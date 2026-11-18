-- SenEdu — migration 0001
-- Socle (comptes, familles), référentiel pédagogique et ressources.
-- Postgres / Supabase. Les tables des cours particuliers viendront en 0002.
--
-- À placer dans supabase/migrations/ puis : supabase db push

-- =====================================================================
-- 1. Types
-- =====================================================================

create type app_role        as enum ('eleve', 'parent', 'prof', 'gestionnaire', 'admin');
create type exam_genre      as enum ('examen', 'concours');
create type resource_genre  as enum ('fiche_cours', 'fiche_methode', 'exercices', 'annale', 'quiz', 'article');
create type niveau_acces    as enum ('gratuit', 'inscrit', 'premium');
create type statut_ressource as enum ('brouillon', 'publiee', 'archivee');
create type mode_creation   as enum ('redigee', 'generee_ia_relue');

-- =====================================================================
-- 2. Référentiel pédagogique
--    Colonne vertébrale : tout s'y rattache (ressources, séances, IA).
-- =====================================================================

create table public.cycles (
  id     smallint primary key generated always as identity,
  nom    text not null unique,            -- Collège, Lycée
  ordre  smallint not null
);

create table public.levels (
  id        smallint primary key generated always as identity,
  cycle_id  smallint not null references public.cycles(id),
  nom       text not null,                -- 6e, Terminale
  slug      text not null unique,
  ordre     smallint not null
);

create table public.series (
  id        smallint primary key generated always as identity,
  level_id  smallint not null references public.levels(id) on delete cascade,
  nom       text not null,                -- S1, S2, L1, L2
  slug      text not null,
  ordre     smallint not null default 0,
  unique (level_id, slug)
);

create table public.subjects (
  id          smallint primary key generated always as identity,
  nom         text not null,
  slug        text not null unique,
  officielle  boolean not null default true,  -- false = module propre à SenEdu
  ordre       smallint not null default 0
);

create table public.chapters (
  id          integer primary key generated always as identity,
  subject_id  smallint not null references public.subjects(id),
  level_id    smallint not null references public.levels(id),
  serie_id    smallint references public.series(id),   -- null au collège
  titre       text not null,
  slug        text not null,
  ordre       smallint not null,
  archive     boolean not null default false
);

-- serie_id étant nullable, l'unicité passe par un index (NULL traité comme 0).
create unique index chapters_identite_idx
  on public.chapters (subject_id, level_id, coalesce(serie_id, 0), slug);
create index chapters_parcours_idx
  on public.chapters (level_id, subject_id, ordre) where not archive;

create table public.notions (
  id          integer primary key generated always as identity,
  chapter_id  integer not null references public.chapters(id) on delete cascade,
  titre       text not null,
  ordre       smallint not null default 0
);

create table public.exams (
  id     smallint primary key generated always as identity,
  nom    text not null unique,            -- BFEM, BAC, EPT, ESP...
  slug   text not null unique,
  genre  exam_genre not null
);

-- =====================================================================
-- 3. Socle : comptes, rôles, élèves, familles
-- =====================================================================

create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  prenom     text,
  nom        text,
  telephone  text,
  ville      text,
  quartier   text,
  cree_le    timestamptz not null default now()
);

create table public.user_roles (
  user_id  uuid not null references public.profiles(id) on delete cascade,
  role     app_role not null,
  primary key (user_id, role)
);

create table public.students (
  profile_id        uuid primary key references public.profiles(id) on delete cascade,
  level_id          smallint references public.levels(id),
  serie_id          smallint references public.series(id),
  etablissement     text,
  premium_jusqu_au  date                   -- null = compte gratuit
);

create table public.families (
  id         uuid primary key default gen_random_uuid(),
  parent_id  uuid not null references public.profiles(id) on delete cascade
);

create table public.family_students (
  family_id   uuid not null references public.families(id) on delete cascade,
  student_id  uuid not null references public.students(profile_id) on delete cascade,
  primary key (family_id, student_id)
);

-- =====================================================================
-- 4. Ressources
--    En V1 la rédaction et la validation se font hors plateforme :
--    les colonnes de traçabilité sont saisies à l'ajout par un admin.
-- =====================================================================

create table public.resources (
  id             uuid primary key default gen_random_uuid(),
  genre          resource_genre not null,
  titre          text not null,
  slug           text not null unique,
  difficulte     smallint check (difficulte between 1 and 3),
  acces          niveau_acces not null default 'inscrit',
  statut         statut_ressource not null default 'brouillon',
  contenu_md     text,                      -- Markdown + LaTeX
  duree_minutes  smallint,
  sources        text,                      -- d'où vient le sujet ou la matière première
  mode           mode_creation,
  validateur     text,                      -- nom du professeur qui a validé
  valide_le      date,
  ajoute_par     uuid references public.profiles(id),
  publie_le      timestamptz,
  maj_le         timestamptz not null default now()
);

create index resources_catalogue_idx on public.resources (statut, genre);

create table public.resource_chapters (
  resource_id  uuid not null references public.resources(id) on delete cascade,
  chapter_id   integer not null references public.chapters(id) on delete cascade,
  primary key (resource_id, chapter_id)
);
create index resource_chapters_chapitre_idx on public.resource_chapters (chapter_id);

create table public.resource_exams (
  id           integer primary key generated always as identity,
  resource_id  uuid not null references public.resources(id) on delete cascade,
  exam_id      smallint not null references public.exams(id),
  annee        smallint,
  serie        text
);
create index resource_exams_examen_idx on public.resource_exams (exam_id, annee);

create table public.quiz_questions (
  id             uuid primary key default gen_random_uuid(),
  resource_id    uuid not null references public.resources(id) on delete cascade,
  enonce         text not null,
  choix          jsonb not null,            -- ["choix A", "choix B", ...]
  bonne_reponse  smallint not null,         -- index dans choix
  explication    text,
  ordre          smallint not null default 0
);

create table public.quiz_attempts (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students(profile_id) on delete cascade,
  resource_id  uuid not null references public.resources(id) on delete cascade,
  score        smallint not null,
  total        smallint not null,
  fait_le      timestamptz not null default now()
);

create table public.resource_views (
  student_id   uuid not null references public.students(profile_id) on delete cascade,
  resource_id  uuid not null references public.resources(id) on delete cascade,
  vu_le        timestamptz not null default now(),
  termine      boolean not null default false,
  primary key (student_id, resource_id)
);

create table public.favorites (
  student_id   uuid not null references public.students(profile_id) on delete cascade,
  resource_id  uuid not null references public.resources(id) on delete cascade,
  ajoute_le    timestamptz not null default now(),
  primary key (student_id, resource_id)
);

-- =====================================================================
-- 5. Sécurité : accès par ligne (RLS)
--    Obligatoire ici : on stocke des données de mineurs.
-- =====================================================================

create or replace function public.a_le_role(r app_role)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid() and ur.role = r
  );
$$;

create or replace function public.est_mon_eleve(eleve uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select eleve = auth.uid()
      or exists (
        select 1
        from public.families f
        join public.family_students fs on fs.family_id = f.id
        where f.parent_id = auth.uid() and fs.student_id = eleve
      );
$$;

alter table public.cycles            enable row level security;
alter table public.levels            enable row level security;
alter table public.series            enable row level security;
alter table public.subjects          enable row level security;
alter table public.chapters          enable row level security;
alter table public.notions           enable row level security;
alter table public.exams             enable row level security;
alter table public.profiles          enable row level security;
alter table public.user_roles        enable row level security;
alter table public.students          enable row level security;
alter table public.families          enable row level security;
alter table public.family_students   enable row level security;
alter table public.resources         enable row level security;
alter table public.resource_chapters enable row level security;
alter table public.resource_exams    enable row level security;
alter table public.quiz_questions    enable row level security;
alter table public.quiz_attempts     enable row level security;
alter table public.resource_views    enable row level security;
alter table public.favorites         enable row level security;

-- Le référentiel est public en lecture, modifiable par les seuls administrateurs.
do $$
declare t text;
begin
  foreach t in array array['cycles','levels','series','subjects','chapters','notions','exams']
  loop
    execute format(
      'create policy %I on public.%I for select using (true)', t || '_lecture', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using (public.a_le_role(''admin'')) with check (public.a_le_role(''admin''))',
      t || '_admin', t);
  end loop;
end $$;

-- Ressources : seules les ressources publiées sont visibles.
-- Le filtre gratuit / inscrit / premium se fait dans l'application,
-- qui ne renvoie que l'aperçu quand l'élève n'y a pas droit.
create policy resources_publiees on public.resources
  for select using (statut = 'publiee' or public.a_le_role('admin'));
create policy resources_admin on public.resources
  for all to authenticated
  using (public.a_le_role('admin')) with check (public.a_le_role('admin'));

create policy resource_chapters_lecture on public.resource_chapters for select using (true);
create policy resource_chapters_admin on public.resource_chapters for all to authenticated
  using (public.a_le_role('admin')) with check (public.a_le_role('admin'));

create policy resource_exams_lecture on public.resource_exams for select using (true);
create policy resource_exams_admin on public.resource_exams for all to authenticated
  using (public.a_le_role('admin')) with check (public.a_le_role('admin'));

create policy quiz_questions_lecture on public.quiz_questions for select using (true);
create policy quiz_questions_admin on public.quiz_questions for all to authenticated
  using (public.a_le_role('admin')) with check (public.a_le_role('admin'));

-- Données personnelles : chacun ne voit que les siennes, le parent celles de ses enfants.
create policy profiles_moi on public.profiles
  for select to authenticated using (id = auth.uid() or public.a_le_role('gestionnaire') or public.a_le_role('admin'));
create policy profiles_maj on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy user_roles_moi on public.user_roles
  for select to authenticated using (user_id = auth.uid() or public.a_le_role('admin'));

create policy students_les_miens on public.students
  for select to authenticated using (public.est_mon_eleve(profile_id) or public.a_le_role('gestionnaire') or public.a_le_role('admin'));
create policy students_maj on public.students
  for update to authenticated using (public.est_mon_eleve(profile_id)) with check (public.est_mon_eleve(profile_id));

create policy families_moi on public.families
  for all to authenticated using (parent_id = auth.uid()) with check (parent_id = auth.uid());
create policy family_students_moi on public.family_students
  for all to authenticated
  using (exists (select 1 from public.families f where f.id = family_id and f.parent_id = auth.uid()))
  with check (exists (select 1 from public.families f where f.id = family_id and f.parent_id = auth.uid()));

create policy quiz_attempts_moi on public.quiz_attempts
  for all to authenticated using (public.est_mon_eleve(student_id)) with check (student_id = auth.uid());
create policy resource_views_moi on public.resource_views
  for all to authenticated using (public.est_mon_eleve(student_id)) with check (student_id = auth.uid());
create policy favorites_moi on public.favorites
  for all to authenticated using (student_id = auth.uid()) with check (student_id = auth.uid());

-- =====================================================================
-- 6. Création automatique du profil à l'inscription
-- =====================================================================

create or replace function public.creer_profil()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, prenom) values (new.id, new.raw_user_meta_data ->> 'prenom');
  insert into public.user_roles (user_id, role) values (new.id, 'eleve');
  return new;
end $$;

create trigger au_nouvel_utilisateur
  after insert on auth.users
  for each row execute function public.creer_profil();
