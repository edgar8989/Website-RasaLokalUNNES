import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const asDate = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : new Date().toISOString().slice(0,10);

export async function GET() {
  try {
    const [menu] = await db.query<any[]>(`
      SELECT p.id_produk AS id,p.nama_produk AS name,k.nama_kategori AS category,
             p.harga AS price,p.tersedia AS available
      FROM produk p JOIN kategori k ON k.id_kategori=p.id_kategori ORDER BY p.id_produk`);
    const [ingredients] = await db.query<any[]>(`
      SELECT id_bahan AS id, nama_bahan AS name, satuan AS unit,
             stok AS stock, stok_minimum AS minimum, harga_beli AS cost
      FROM bahan_baku ORDER BY id_bahan`);
    const [sales] = await db.query<any[]>(`
      SELECT ps.id_pesanan AS id,DATE_FORMAT(ps.tanggal,'%Y-%m-%d') AS date,
             pl.nama AS customer,
             COALESCE(ps.ringkasan, GROUP_CONCAT(CONCAT(d.jumlah,'x ',pr.nama_produk) ORDER BY d.id_detail SEPARATOR ', '),'Pesanan') AS items,
             COALESCE(NULLIF(ps.total_tagihan,0),SUM(d.jumlah*d.harga_satuan),0) AS total,
             CASE WHEN pay.id_bayar IS NULL THEN 'Belum dibayar' ELSE 'Lunas' END AS payment
      FROM pesanan ps JOIN pelanggan pl ON pl.id_pelanggan=ps.id_pelanggan
      LEFT JOIN detail_pesanan d ON d.id_pesanan=ps.id_pesanan
      LEFT JOIN produk pr ON pr.id_produk=d.id_produk
      LEFT JOIN pembayaran pay ON pay.id_pesanan=ps.id_pesanan
      GROUP BY ps.id_pesanan,ps.tanggal,pl.nama,ps.ringkasan,ps.total_tagihan,pay.id_bayar
      ORDER BY ps.tanggal DESC,ps.id_pesanan DESC`);
    const [expenses] = await db.query<any[]>(`
      SELECT id_pengeluaran AS id,DATE_FORMAT(tanggal,'%Y-%m-%d') AS date,
             kategori AS category,keterangan AS note,jumlah AS amount
      FROM pengeluaran ORDER BY tanggal DESC,id_pengeluaran DESC`);
    const [suppliers] = await db.query<any[]>(`
      SELECT p.id_pemasok AS id,p.nama_pemasok AS name,COALESCE(p.no_hp,'') AS contact,
             COALESCE(GROUP_CONCAT(DISTINCT b.nama_bahan SEPARATOR ', '),'') AS item
      FROM pemasok p LEFT JOIN bahan_baku b ON b.id_pemasok=p.id_pemasok
      GROUP BY p.id_pemasok,p.nama_pemasok,p.no_hp ORDER BY p.id_pemasok`);
    const [purchases] = await db.query<any[]>(`
      SELECT pb.id_pembelian AS id,DATE_FORMAT(pb.tanggal,'%Y-%m-%d') AS date,
             pm.nama_pemasok AS supplier,bb.nama_bahan AS ingredient,
             pb.jumlah AS qty,pb.total
      FROM pembelian pb JOIN pemasok pm ON pm.id_pemasok=pb.id_pemasok
      JOIN bahan_baku bb ON bb.id_bahan=pb.id_bahan
      ORDER BY pb.tanggal DESC,pb.id_pembelian DESC`);
    return NextResponse.json({menu,ingredients,sales,expenses,suppliers,purchases});
  } catch (error) {
    console.error('MySQL GET error:', error);
    return NextResponse.json({error:'Gagal membaca database Rasa Lokal. Periksa schema.sql dan koneksi MySQL.'},{status:500});
  }
}

export async function PUT(request: Request) {
  let c:any;
  try {
    const data = await request.json();
    for (const k of ['menu','ingredients','sales','expenses','suppliers','purchases']) {
      if (!Array.isArray(data[k])) return NextResponse.json({error:`Data ${k} tidak valid.`},{status:400});
    }
    c=await db.getConnection(); await c.beginTransaction();

    // Pertahankan relasi resep serta data kontak pelanggan yang tidak diedit oleh UI.
    const [savedRecipes]=await c.query('SELECT id_produk,id_bahan,jumlah_pakai FROM resep');
    const [savedCustomers]=await c.query('SELECT nama,no_hp,alamat FROM pelanggan');
    const customerDetails=new Map<string,{no_hp:string|null;alamat:string|null}>(
      savedCustomers.map((x:any)=>[String(x.nama),{no_hp:x.no_hp,alamat:x.alamat}])
    );

    // Snapshot sync untuk prototipe satu operator. Hapus tabel anak sebelum induk.
    await c.query('DELETE FROM pembayaran');
    await c.query('DELETE FROM detail_pesanan');
    await c.query('DELETE FROM pesanan');
    await c.query('DELETE FROM pembelian');
    await c.query('DELETE FROM pengeluaran');
    await c.query('DELETE FROM resep');
    await c.query('DELETE FROM produk');
    await c.query('DELETE FROM bahan_baku');
    await c.query('DELETE FROM pelanggan');
    await c.query('DELETE FROM pemasok');
    await c.query('DELETE FROM kategori');

    const catIds=new Map<string,number>();
    for (const x of data.menu) {
      const cat=String(x.category||'Lainnya');
      if (!catIds.has(cat)) {
        const [r]=await c.execute('INSERT INTO kategori (nama_kategori) VALUES (?)',[cat]);
        catIds.set(cat,Number(r.insertId));
      }
      await c.execute('INSERT INTO produk (id_produk,id_kategori,nama_produk,harga,tersedia) VALUES (?,?,?,?,?)',
        [x.id,catIds.get(cat),x.name,Number(x.price),x.available?1:0]);
    }

    const supplierIds=new Map<string,number>();
    for (const s of data.suppliers) {
      const [r]=await c.execute('INSERT INTO pemasok (id_pemasok,nama_pemasok,no_hp) VALUES (?,?,?)',
        [s.id,s.name,s.contact||null]);
      supplierIds.set(String(s.name),Number(s.id));
    }
    const defaultSupplier=async()=> {
      if (!supplierIds.has('Pemasok umum')) {
        const [r]=await c.execute('INSERT INTO pemasok (nama_pemasok,no_hp) VALUES (?,NULL)',['Pemasok umum']);
        supplierIds.set('Pemasok umum',Number(r.insertId));
      }
      return supplierIds.get('Pemasok umum')!;
    };
    const ingredientIds=new Map<string,number>();
    for (const x of data.ingredients) {
      const matchedSupplier = data.suppliers.find((s:any) =>
        String(s.item||'').split(',').map((v:string)=>v.trim()).includes(String(x.name)));
      const sid = matchedSupplier ? (supplierIds.get(String(matchedSupplier.name)) || await defaultSupplier()) : await defaultSupplier();
      await c.execute(`INSERT INTO bahan_baku
        (id_bahan,id_pemasok,nama_bahan,satuan,stok,harga_beli,stok_minimum)
        VALUES (?,?,?,?,?,?,?)`,
        [x.id,sid,x.name,x.unit,Number(x.stock),Number(x.cost),Number(x.minimum||0)]);
      ingredientIds.set(String(x.name),Number(x.id));
    }
    // Pulihkan resep setelah produk dan bahan baku dibuat ulang dengan ID yang sama.
    const productIdSet=new Set(data.menu.map((x:any)=>Number(x.id)));
    const ingredientIdSet=new Set(data.ingredients.map((x:any)=>Number(x.id)));
    for (const recipe of savedRecipes) {
      if (productIdSet.has(Number(recipe.id_produk)) && ingredientIdSet.has(Number(recipe.id_bahan))) {
        await c.execute('INSERT INTO resep (id_produk,id_bahan,jumlah_pakai) VALUES (?,?,?)',
          [recipe.id_produk,recipe.id_bahan,recipe.jumlah_pakai]);
      }
    }

    const customerIds=new Map<string,number>();
    for (const s of data.sales) {
      const customer=String(s.customer||'Pelanggan umum');
      if (!customerIds.has(customer)) {
        const details=customerDetails.get(customer);
        const [r]=await c.execute('INSERT INTO pelanggan (nama,no_hp,alamat) VALUES (?,?,?)',
          [customer,details?.no_hp||null,details?.alamat||null]);
        customerIds.set(customer,Number(r.insertId));
      }
      const total=Number(s.total)||0;
      const paid=s.payment==='Lunas';
      const [r]=await c.execute(`INSERT INTO pesanan
        (id_pesanan,id_pelanggan,tanggal,status,metode_antar,ringkasan,total_tagihan)
        VALUES (?,?,?,?,?,?,?)`,
        [s.id,customerIds.get(customer),asDate(s.date),paid?'selesai':'diproses','ambil',String(s.items||''),total]);
      const summary=String(s.items||'');
      const matches=[...summary.matchAll(/(\d+)\s*x\s*(.+?)(?=,\s*\d+\s*x\s*|$)/gi)];
      for (const m of matches) {
        const productName=m[2].trim();
        const [rows]=await c.execute('SELECT id_produk,harga FROM produk WHERE nama_produk=? LIMIT 1',[productName]);
        if (rows.length) await c.execute(
          'INSERT INTO detail_pesanan (id_pesanan,id_produk,jumlah,harga_satuan) VALUES (?,?,?,?)',
          [s.id,rows[0].id_produk,Number(m[1]),Number(rows[0].harga)]);
      }
      if (paid) await c.execute(
        'INSERT INTO pembayaran (id_pesanan,total,metode,tgl_bayar) VALUES (?,?,?,?)',
        [s.id,total,'tunai',asDate(s.date)]);
    }
    for (const x of data.purchases) {
      const sid=supplierIds.get(String(x.supplier)) || await defaultSupplier();
      const iid=ingredientIds.get(String(x.ingredient));
      if (iid) await c.execute(
        'INSERT INTO pembelian (id_pembelian,tanggal,id_pemasok,id_bahan,jumlah,total) VALUES (?,?,?,?,?,?)',
        [x.id,asDate(x.date),sid,iid,Number(x.qty),Number(x.total)]);
    }
    for (const x of data.expenses) await c.execute(
      'INSERT INTO pengeluaran (id_pengeluaran,tanggal,kategori,keterangan,jumlah) VALUES (?,?,?,?,?)',
      [x.id,asDate(x.date),x.category,x.note,Number(x.amount)]);
    await c.commit();
    return NextResponse.json({ok:true});
  } catch(error) {
    if(c) await c.rollback();
    console.error('MySQL PUT error:',error);
    return NextResponse.json({error:'Gagal menyimpan data ke database ERD Eric. Periksa data dan relasi tabel.'},{status:500});
  } finally { c?.release(); }
}
