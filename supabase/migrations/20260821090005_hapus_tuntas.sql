-- 005 - Make account deletion actually total.
--
-- docs/03 §2 declares log_batas_aman.pengguna_id as ON DELETE SET NULL, which
-- keeps the row after the account is gone. That row holds `pertanyaan`: the
-- question the caregiver typed. A question only trips the medical boundary when
-- someone is asking about their own child, so it is the most identifying text
-- in the system and it very often contains the child's name.
--
-- Bab 4.3 promises the user can delete their account and all related data.
-- Keeping an orphaned copy of their most sensitive sentences would break that
-- promise in the one place nobody would think to look.
--
-- The monitoring panel in docs/04 §5 counts boundary hits by category to spot a
-- model starting to leak. That still works: it is about live behaviour, not
-- about retaining the history of an account that asked to be forgotten.

alter table log_batas_aman
  drop constraint log_batas_aman_pengguna_id_fkey;

alter table log_batas_aman
  add constraint log_batas_aman_pengguna_id_fkey
  foreign key (pengguna_id) references pengguna (id) on delete cascade;
