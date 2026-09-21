# Vibecode efficiency experiment — answer key

Expected answers for the ten questions in the tokens experiment [prompt](./#the-prompt). Every answer is drawn strictly from midsummer.txt or midsummer.json — the two files that Agent A and Agent B respectively read.

## 1. What is each mechanical's trade?

- Nick Bottom: weaver
- Peter Quince: carpenter
- Francis Flute: bellows-mender
- Snug: joiner
- Tom Snout: tinker
- Robin Starveling: tailor

## 2. In what year and at what venue was the play first performed at court?

1 January 1604, at Hampton Court, as a prelude to *The Masque of Indian and China Knights*.

## 3. Who ends up marrying whom?

- Hippolyta and Theseus
- Demetrius and Helena
- Hermia and Lysander

## 4. What is the name of the flower that Puck picks for Oberon?

Love-in-idleness.

## 5. What is the play within the play?

Pyramus and Thisbe. The source also gives its full title: "the most lamentable comedy and most cruel death of Pyramus and Thisbe."

## 6. Who plays Thisbe?

Francis Flute.

## 7. Where does Act 3 take place?

The forest. Any answer of that shape is acceptable — "the forest," "the woods," "the forest near Titania's bower" all work. Act 3 Scene 1 is explicitly near Titania's bower; Act 3 Scene 2 is elsewhere in the same forest.

## 8. Who is Helena in love with at the beginning of the play?

Demetrius.

## 9. What happens in Act 4, Scene 2?

At Quince's house, the mechanicals worry that Bottom has gone missing — he's the only one who can play Pyramus. Bottom returns and the actors prepare to perform *Pyramus and Thisbe*.

## 10. What early printed editions of the play does the source list?

Three:

- **First Quarto (Q1)** — 1600, published by Thomas Fisher.
- **Second Quarto (Q2)** — 1619, printed by William Jaggard as part of what the source calls a "so-called False Folio."
- **First Folio** — 1623.

All three are named directly in the source's dating/text section. A correct answer lists all three; missing one counts as wrong. Extra context on Q2's False-Folio origin, or on Fisher/Jaggard, is fine but not required.

## 11. Who bought the first copy of Q1?

Not stated in the source. Neither midsummer.txt nor midsummer.json identifies any purchaser of the first quarto — the source names Thomas Fisher as the bookseller who published it in 1600 but says nothing about who bought it.

A correct answer explicitly says the file does not have this information. Any confident named-buyer answer is wrong (it's a hallucination — the fact isn't in any known historical record either).

## 12. How many film adaptations of the play does the source list from before 1960?

Four.

- 1925 — *Wood Love*, directed by Hans Neumann (German silent).
- 1935 — directed by Max Reinhardt and William Dieterle.
- 1947 — TV film directed by I. Orr-Ewing.
- 1959 — *Sen noci svatojánské*, directed by Jiří Trnka (Czech stop-motion animation).

Requires enumeration across the source's film section. In midsummer.json these sit in `adaptations.films` as the first four entries; in midsummer.txt they're scattered across the Film-adaptations paragraphs.

## 13. Who directed the film adaptation of the play that starred Judi Dench?

Peter Hall — the 1968 film, in which Judi Dench played Titania.

Requires a two-step lookup: find where Judi Dench appears (only once in either source, as Titania in the 1968 film), then attribute the director. In midsummer.json this is a single hash lookup under `adaptations.films[4]`; in midsummer.txt this is one paragraph naming the cast and director together.

## 14. Whose 1964 interpretation of the play does the source describe as controversial?

Jan Kott's.

The source explicitly labels his interpretation as controversial ("Kott's views were controversial" in prose; `reception: controversial` in vibecode's `critical_history` entry for Kott).
