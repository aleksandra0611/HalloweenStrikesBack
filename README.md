# Halloween Strikes Back 🎃

2D pixel art igra tipa "lane battler", izdelana v Godotu 4.6.1. Kot Jack the Pumpkin vodiš vojsko Noč čarovnic proti božični vojski, ki je prezgodaj vdrla v oktober.


## Navodila za zagon

**Zahteve:** Windows 10/11 (64-bit). Namestitev ni potrebna.

1. Prenesite celotno mapo `Release/`.
2. Če je prenesena kot ZIP, jo najprej razpakirajte.
3. V mapi razširite oz. razpakirajte še priloženi ZIP arhiv, v katerem se nahaja `Halloween strikes back.exe` 
4. Zaženite `Halloween strikes back.exe`.
5. Če Windows prikaže opozorilo SmartScreen ("neznani založnik"), kliknite **Več informacij > Vseeno zaženi**.


### Zagon iz izvorne kode

1. Namestite [Godot 4.6.1](https://godotengine.org/download).
2. V Godot Project Manager izberite **Import** in odprite `Source/project.godot`.
3. Pritisnite **F5** (Run Project).

## Načina igre

- **Zgodba (Story):** dve stopnji. Uničite sovražnikovo bazo, preden sovražnik uniči vašo. Druga stopnja je težja (hitrejši dohodek in hitrejši udarci sovražnikov).
- **Neskončni način (Endless):** ni sovražnikove baze. Preživite čim več valov. Med valovi dobite premor in bonus zlato. Najboljši rezultat se shrani.

## Kontrole

| Akcija | Kontrola |
|---|---|
| Nakup enote | Klik na gumb enote (Bat, Ghost, Jack, Skeleton) |
| Premik kamere po zemljevidu | **A** (levo) in **D** (desno) |
| Napad (Attack) | Gumb **Attack**: vojska koraka proti sovražnikovi bazi |
| Obramba (Defend) | Gumb **Defend**: vojska drži črto pri vaši bazi in jo zdravi |
| Napredovanje (Advance, Endless) | Gumb **Advance**: vojska se postavi na prednjo črto |
| Pavza | Gumb za pavzo v zaslonu igre |
| Preskok dialoga | Klik med zgodbo |
| Bonus (F2) | Pokliče 5 pumpkin enot |

## Pravila igre na kratko

- Enote stanejo zlato. Zlato dobite s časom in z ubijanjem sovražnikov.
- Vrsta za treniranje sprejme največ 5 enot.
- Bat in Ghost sta na voljo takoj. Jack se odklene pri **10** ubitih sovražnikih, Skeleton pri **15**.
- Ko odklenete novo enoto, se odklene tudi nova sovražnikova enota.
- Odklepanja se v drugi stopnji začnejo znova.

## Povezave

- **Dokumentacija:** [Documentation/](Documentation/)
- **Video predstavitve:** *(vstavi povezavo)*

## Ekipa
Aleksandra Mickoska, 
Daniel Adamcheski

## Tehnologija

- Godot 4.6.1 (GDScript)