import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export const runtime='nodejs';
export const dynamic='force-dynamic';

export async function PATCH(_request:Request, context:{params:Promise<{id:string}>}) {
 const {id:raw}=await context.params;
 const id=Number(raw);
 if(!Number.isSafeInteger(id)||id<=0) return NextResponse.json({error:'ID pesanan tidak valid.'},{status:400});
 let c:any;
 try {
  c=await db.getConnection(); await c.beginTransaction();
  const [rows]=await c.execute(
   `SELECT ps.id_pesanan,ps.tanggal,ps.total_tagihan,
    COALESCE(NULLIF(ps.total_tagihan,0),SUM(d.jumlah*d.harga_satuan),0) AS total,
    pay.id_bayar
    FROM pesanan ps LEFT JOIN detail_pesanan d ON d.id_pesanan=ps.id_pesanan
    LEFT JOIN pembayaran pay ON pay.id_pesanan=ps.id_pesanan
    WHERE ps.id_pesanan=? GROUP BY ps.id_pesanan,ps.tanggal,ps.total_tagihan,pay.id_bayar FOR UPDATE`,[id]);
  if(!rows.length){await c.rollback();return NextResponse.json({error:'Pesanan tidak ditemukan.'},{status:404});}
  if(rows[0].id_bayar){await c.rollback();return NextResponse.json({error:'Pesanan sudah Lunas dan tidak dapat diubah kembali.'},{status:409});}
  await c.execute('INSERT INTO pembayaran (id_pesanan,total,metode,tgl_bayar) VALUES (?,?,?,?)',
    [id,Number(rows[0].total),'tunai',new Date().toISOString().slice(0,10)]);
  await c.execute("UPDATE pesanan SET status='selesai' WHERE id_pesanan=?",[id]);
  await c.commit();
  return NextResponse.json({ok:true,id,payment:'Lunas'});
 } catch(e) {
  if(c) await c.rollback();
  console.error('Payment PATCH error:',e);
  return NextResponse.json({error:'Gagal menyimpan pembayaran ke MySQL.'},{status:500});
 } finally {c?.release();}
}
