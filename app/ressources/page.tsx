import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
export const instant = false;

type Chapitre = {
  id: number;
  titre: string;
  ordre: number;
  subjects: { nom: string } | null;
  levels: { nom: string } | null;
  series: { nom: string } | null;
};

export default async function Ressources() {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("chapters")
    .select("id, titre, ordre, subjects(nom), levels(nom), series(nom)")
    .eq("archive", false)
    .order("ordre");

  if (error) {
    return (
      <main className="mx-auto max-w-3xl px-8 py-24">
        <h1 className="font-serif text-3xl font-semibold">
          Les ressources sont indisponibles
        </h1>
        <p className="mt-4 text-gris">{error.message}</p>
      </main>
    );
  }

  const chapitres = (data ?? []) as unknown as Chapitre[];

  // Regroupe les chapitres par matière, niveau et série.
  const groupes = new Map<string, Chapitre[]>();
  for (const chapitre of chapitres) {
    const serie = chapitre.series?.nom ? ` ${chapitre.series.nom}` : "";
    const cle = `${chapitre.subjects?.nom ?? "Matière"} en ${chapitre.levels?.nom ?? ""}${serie}`;
    groupes.set(cle, [...(groupes.get(cle) ?? []), chapitre]);
  }

  return (
    <main className="mx-auto max-w-4xl px-8 py-20">
      <Link href="/" className="font-serif text-xl font-semibold text-vert">
        SenEdu
      </Link>

      <h1 className="mt-10 font-serif text-4xl leading-tight font-semibold tracking-tight">
        Les ressources
      </h1>
      <p className="mt-4 max-w-[60ch] leading-relaxed text-encre-douce">
        Le programme, rangé comme dans vos cours. Chaque chapitre réunira ses
        fiches, ses exercices corrigés, son quiz et ses annales.
      </p>

      {groupes.size === 0 && (
        <p className="mt-12 text-gris">
          Aucun chapitre pour l’instant. Chargez le référentiel dans Supabase.
        </p>
      )}

      {[...groupes].map(([titre, liste]) => (
        <section key={titre} className="mt-14">
          <h2 className="border-t-2 border-vert pt-4 font-serif text-xl font-medium">
            {titre}
          </h2>
          <ul>
            {liste.map((chapitre) => (
              <li
                key={chapitre.id}
                className="flex items-baseline gap-4 border-t border-trait py-4"
              >
                <span className="w-6 shrink-0 text-sm text-gris">
                  {chapitre.ordre}
                </span>
                <span className="font-serif text-lg">{chapitre.titre}</span>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </main>
  );
}
