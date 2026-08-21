-- 006 - Make the activity catalogue seedable more than once.
--
-- docs/07 §6 requires the seed to be idempotent: running it twice must not
-- duplicate anything. Without a natural key there is nothing for ON CONFLICT to
-- key off, so a second `supabase db reset` against an existing database would
-- silently double the catalogue and every plan drawn from it.
--
-- Title within a category and level is the natural key: two activities at the
-- same level of the same category may not share a name, or the caregiver
-- cannot tell them apart on the plan screen either.

alter table aktivitas
  add constraint aktivitas_judul_unik unique (kategori, tingkat, judul);

-- Steps address the child by name. The catalogue is shared by every account, so
-- it cannot contain a real name: the app substitutes {nama} at render time.
-- This keeps a literal name from ever being seeded into shared content.
comment on column aktivitas.langkah is
  'Array of {urutan, teks}. Use the {nama} placeholder for the child''s nickname.';

comment on column aktivitas.tujuan is
  'One sentence naming the behaviour being practised. Use {nama} for the child.';

comment on column aktivitas.cocok_untuk_komunikasi is
  'Communication abilities this activity suits, used by generate-plan to filter.';
