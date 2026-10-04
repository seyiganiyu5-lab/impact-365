-- Sample content so the app has something to show on day one.
-- Run it in the Supabase SQL editor after the migration (safe to re-run).

with d as (
  insert into public.devotions (devotion_date, slot, is_published)
  values
    (current_date, 'morning',   true),
    (current_date, 'afternoon', true),
    (current_date, 'night',     true)
  on conflict (devotion_date, slot) do update set is_published = true
  returning id, slot
)
insert into public.devotion_translations
  (devotion_id, lang, theme, verse_reference, verse_text, god_says, i_understand, i_do)
select d.id, t.lang::public.app_language, t.theme, t.ref, t.verse, t.says, t.understand, t.act
from d
join (values
  -- Morning
  ('morning', 'fr', 'Dieu a un plan plus grand que le tien.', 'Matthieu 6:33',
   'Cherchez premièrement le royaume et la justice de Dieu, et toutes ces choses vous seront données par-dessus.',
   'Dieu nous invite à placer son royaume en premier dans notre vie.',
   'Si je cherche d''abord Dieu, Il pourvoira à tout le reste. Ce n''est pas une promesse pour demain, c''est un principe pour aujourd''hui.',
   'Aujourd''hui, je choisis de prioriser Dieu dans mes décisions, mes pensées et mon temps.'),
  ('morning', 'en', 'God has a bigger plan than yours.', 'Matthew 6:33',
   'But seek first his kingdom and his righteousness, and all these things will be given to you as well.',
   'God invites us to put His kingdom first in our lives.',
   'If I seek God first, He will provide for everything else. It is not a promise for tomorrow, it is a principle for today.',
   'Today, I choose to prioritise God in my decisions, my thoughts and my time.'),
  ('morning', 'yo', 'Ọlọ́run ní ètò tó tóbi ju tìrẹ lọ.', 'Mátíù 6:33',
   'Ṣùgbọ́n ẹ kọ́kọ́ máa wá ìjọba Ọlọ́run àti òdodo rẹ̀, gbogbo nǹkan wọ̀nyí ni a ó sì fi kún un fún yín.',
   'Ọlọ́run pè wá láti fi ìjọba Rẹ̀ sí ipò àkọ́kọ́ nínú ayé wa.',
   'Bí mo bá kọ́kọ́ wá Ọlọ́run, Òun yóò pèsè gbogbo ohun yòókù.',
   'Lónìí, mo yàn láti fi Ọlọ́run ṣáájú nínú ìpinnu, èrò àti àkókò mi.'),
  -- Afternoon
  ('afternoon', 'fr', 'Ses pensées sont plus hautes.', 'Ésaïe 55:8',
   'Car mes pensées ne sont pas vos pensées, et vos voies ne sont pas mes voies, dit l''Éternel.',
   'Dieu voit plus loin que moi.',
   'Quand je ne comprends pas, je peux faire confiance à Celui qui voit tout.',
   'Cet après-midi, je remets à Dieu la situation que je ne comprends pas.'),
  ('afternoon', 'en', 'His thoughts are higher.', 'Isaiah 55:8',
   '"For my thoughts are not your thoughts, neither are your ways my ways," declares the Lord.',
   'God sees further than I do.',
   'When I do not understand, I can trust the One who sees everything.',
   'This afternoon, I hand over to God the situation I do not understand.'),
  -- Night
  ('night', 'fr', 'Repose-toi en Lui.', 'Psaume 4:8',
   'Je me couche et je m''endors en paix, car toi seul, ô Éternel ! tu me donnes la sécurité dans ma demeure.',
   'La paix vient de Dieu, pas des circonstances.',
   'Je peux déposer ma journée entre ses mains avant de dormir.',
   'Ce soir, je remercie Dieu pour trois choses et je Lui confie demain.'),
  ('night', 'en', 'Rest in Him.', 'Psalm 4:8',
   'In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.',
   'Peace comes from God, not from circumstances.',
   'I can place my day in His hands before I sleep.',
   'Tonight, I thank God for three things and entrust tomorrow to Him.')
) as t(slot, lang, theme, ref, verse, says, understand, act)
  on t.slot = d.slot::text
on conflict (devotion_id, lang) do nothing;

with c as (
  insert into public.challenges (challenge_date, is_published)
  values (current_date, true)
  on conflict (challenge_date) do update set is_published = true
  returning id
)
insert into public.challenge_translations (challenge_id, lang, title, description, verse_reference, verse_text)
select c.id, t.lang::public.app_language, t.title, t.descr, t.ref, t.verse
from c, (values
  ('fr', 'Aujourd''hui, encourage sincèrement une personne qui traverse une période difficile.',
         'Un message, un appel ou une visite. Un petit geste, un grand impact.',
         '1 Corinthiens 16:14', 'Que tout ce que vous faites soit fait avec amour.'),
  ('en', 'Today, sincerely encourage someone who is going through a hard time.',
         'A message, a call or a visit. A small gesture, a great impact.',
         '1 Corinthians 16:14', 'Do everything in love.'),
  ('yo', 'Lónìí, fi tọkàntọkàn gba ẹnìkan tí ń la àkókò líle kọjá níyànjú.',
         'Ìfiránṣẹ́, ìpè tàbí ìbẹ̀wò. Ìṣe kékeré, ipa ńlá.',
         '1 Kọ́ríńtì 16:14', 'Ẹ jẹ́ kí ohun gbogbo tí ẹ ń ṣe jẹ́ nínú ìfẹ́.')
) as t(lang, title, descr, ref, verse)
on conflict (challenge_id, lang) do nothing;

insert into public.announcements (title, body)
select 'Bienvenue dans la famille Impact-365 !',
       'Découvre chaque jour ta dévotion du matin, de l''après-midi et du soir.'
where not exists (select 1 from public.announcements);
