-- F4 - koreksi manual pengasuh sebagai jenis baris tersendiri di adaptasi_log.
--
-- Sebelumnya koreksi manual ditulis dengan `aturan_id = 'C_porsi'` supaya lolos
-- check constraint. Itu keliru dan menular: layar Rencana membaca `aturan_id`
-- untuk menjelaskan *mengapa* rencana berubah, dan baris yang menyamar sebagai
-- aturan C akan dijelaskan sebagai keputusan mesin padahal keputusan pengasuh.
--
-- KF-06 menjanjikan pengasuh dapat mengoreksi rencana dan koreksinya dihormati.
-- Janji itu hanya dapat diaudit kalau koreksinya punya nama sendiri di log.
alter table public.adaptasi_log
  drop constraint if exists adaptasi_log_aturan_id_check;

alter table public.adaptasi_log
  add constraint adaptasi_log_aturan_id_check
  check (aturan_id in ('A_naik', 'B_turun', 'C_porsi', 'D_tandai', 'E_jadwal',
                       'F_profesional', 'G_manual'));

comment on column public.adaptasi_log.aturan_id is
  'A-E: lima aturan otomatis F4. F_profesional: saran tenaga profesional yang '
  'diterapkan pengasuh. G_manual: koreksi langsung oleh pengasuh (KF-06).';
