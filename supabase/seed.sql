-- SenEdu — données de départ du référentiel
-- Les niveaux, séries, matières et examens sont complets.
-- Les chapitres ne contiennent qu'un exemple travaillé (maths Terminale S2) :
-- le reste est importé depuis le tableur du référentiel que remplit Babacar.

-- ---------------------------------------------------------------------
-- Cycles et niveaux
-- ---------------------------------------------------------------------

insert into public.cycles (nom, ordre) values
  ('Collège', 1),
  ('Lycée',   2);

insert into public.levels (cycle_id, nom, slug, ordre)
select c.id, v.nom, v.slug, v.ordre
from (values
  ('Collège', '6e',        '6e',        1),
  ('Collège', '5e',        '5e',        2),
  ('Collège', '4e',        '4e',        3),
  ('Collège', '3e',        '3e',        4),
  ('Lycée',   'Seconde',   '2nde',      5),
  ('Lycée',   'Première',  '1re',       6),
  ('Lycée',   'Terminale', 'terminale', 7)
) as v(cycle, nom, slug, ordre)
join public.cycles c on c.nom = v.cycle;

-- Séries du lycée. À compléter selon ce que vous couvrez réellement.
insert into public.series (level_id, nom, slug, ordre)
select l.id, v.nom, v.slug, v.ordre
from (values
  ('2nde',      'Seconde S', 's',  1),
  ('2nde',      'Seconde L', 'l',  2),
  ('1re',       'S1',        's1', 1),
  ('1re',       'S2',        's2', 2),
  ('1re',       'L1',        'l1', 3),
  ('1re',       'L2',        'l2', 4),
  ('terminale', 'S1',        's1', 1),
  ('terminale', 'S2',        's2', 2),
  ('terminale', 'L1',        'l1', 3),
  ('terminale', 'L2',        'l2', 4)
) as v(niveau, nom, slug, ordre)
join public.levels l on l.slug = v.niveau;

-- ---------------------------------------------------------------------
-- Matières
-- ---------------------------------------------------------------------

insert into public.subjects (nom, slug, officielle, ordre) values
  ('Mathématiques',              'maths',           true,  1),
  ('Physique-chimie',            'physique-chimie', true,  2),
  ('Sciences de la vie et de la Terre', 'svt',      true,  3),
  ('Programmation',              'programmation',   false, 4),
  ('Sciences de l''ingénieur',   'sciences-ingenieur', false, 5),
  ('Éducation financière',       'education-financiere', false, 6),
  ('Citoyenneté',                'citoyennete',     false, 7),
  ('Culture générale',           'culture-generale', false, 8);

-- ---------------------------------------------------------------------
-- Examens et concours
-- ---------------------------------------------------------------------

insert into public.exams (nom, slug, genre) values
  ('BFEM',  'bfem',  'examen'),
  ('BAC',   'bac',   'examen'),
  ('EPT',   'ept',   'concours'),
  ('ESP',   'esp',   'concours'),
  ('IPSL',  'ipsl',  'concours'),
  ('ENSAE', 'ensae', 'concours'),
  ('INSA',  'insa',  'concours'),
  ('EMS',   'ems',   'concours');

-- ---------------------------------------------------------------------
-- Exemple travaillé : mathématiques en Terminale S2
-- Vérifier l'ordre et les intitulés avec le programme officiel.
-- ---------------------------------------------------------------------

insert into public.chapters (subject_id, level_id, serie_id, titre, slug, ordre)
select s.id, l.id, se.id, v.titre, v.slug, v.ordre
from (values
  ('Suites numériques',               'suites-numeriques',            1),
  ('Limites et continuité',           'limites-continuite',           2),
  ('Dérivation et étude de fonctions','derivation-etude-fonctions',   3),
  ('Fonctions exponentielles',        'fonctions-exponentielles',     4),
  ('Fonctions logarithmes',           'fonctions-logarithmes',        5),
  ('Calcul intégral',                 'calcul-integral',              6),
  ('Nombres complexes',               'nombres-complexes',            7),
  ('Équations différentielles',       'equations-differentielles',    8),
  ('Probabilités',                    'probabilites',                 9),
  ('Statistique à deux variables',    'statistique-deux-variables',  10),
  ('Géométrie dans l''espace',        'geometrie-espace',            11),
  ('Similitudes planes',              'similitudes-planes',          12)
) as v(titre, slug, ordre)
cross join (select id from public.subjects where slug = 'maths') s
cross join (select id from public.levels   where slug = 'terminale') l
cross join (select se.id from public.series se
            join public.levels l2 on l2.id = se.level_id
            where l2.slug = 'terminale' and se.slug = 's2') se;

-- Notions du chapitre 5, pour montrer le niveau de détail attendu.
insert into public.notions (chapter_id, titre, ordre)
select c.id, v.titre, v.ordre
from (values
  ('Définition de la fonction ln',        1),
  ('Propriétés algébriques',              2),
  ('Dérivée et sens de variation',        3),
  ('Limites aux bornes',                  4),
  ('Équations et inéquations avec ln',    5),
  ('Étude de fonctions contenant ln',     6)
) as v(titre, ordre)
cross join (select id from public.chapters where slug = 'fonctions-logarithmes') c;
