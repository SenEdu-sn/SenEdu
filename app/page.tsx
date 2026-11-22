import Link from "next/link";

export default function Accueil() {
  return (
    <main className="mx-auto max-w-5xl px-8 py-24">
      <h1 className="max-w-[15ch] font-serif text-5xl leading-[1.05] font-semibold tracking-tight sm:text-6xl">
        Le programme sénégalais, chapitre par chapitre.
      </h1>

      <p className="mt-8 max-w-[46ch] text-lg leading-relaxed text-encre-douce">
        Des fiches de cours et des annales corrigées pour le BFEM, le bac et les
        concours des grandes écoles. Un assistant qui répond aux questions à
        toute heure. Et, à Dakar, des professeurs à domicile.
      </p>

      <div className="mt-10 flex flex-wrap gap-3">
        <Link
          href="/ressources"
          className="flex min-h-13 items-center rounded px-6 font-medium text-white bg-violet hover:bg-violet-sombre"
        >
          Ouvrir les ressources
        </Link>
        <span className="flex min-h-13 items-center rounded border border-trait px-6 font-medium text-gris">
          Cours particuliers, bientôt à Dakar
        </span>
      </div>
    </main>
  );
}
