import Foundation
import SwiftUI

// MARK: - Catalog — the whole of La Shop, in one place (iOS port)
//
// Le Portail (iOS) is the pocket gateway to every Atelier app Jac has built.
// This file is the single source of truth, ported from the macOS Le Portail's
// Catalog.swift and adapted for iPhone:
//
//   • A `platform` field — .web / .iOS / .mac — derived from each entry.
//       - web : the app has a live https URL → opens in SFSafariViewController.
//       - iOS : a native app that lives on this iPhone (no /Applications/ path
//               in the macOS source; it ships as an iOS-only Xcode project).
//       - mac : a native macOS app (an /Applications/*.app path). Not launchable
//               from an iPhone — shown as an honest info card.
//
//   • Bilingual taglines + the 7 Atelier themes are preserved verbatim.
//
// This file is compiled into BOTH the app target and the widget extension via
// the shared app group, so the Délice-du-jour pick and the data are identical
// in the app and on the Home Screen widget.
//
// Maintenance: append an `AppEntry(...)` in the right `Theme` block. Web apps need a
// `url`; native apps need a `platform` (.iOS or .mac) and optionally a bundleID.

// MARK: Platform

enum Platform: String, Codable, CaseIterable, Identifiable {
    case web    // live web app — opens in-app Safari
    case iOS    // native iPhone/iPad app on this device
    case mac    // native macOS app (not launchable here)

    var id: String { rawValue }

    /// Short chip label, bilingual.
    func badge(_ lang: Lang) -> String {
        switch self {
        case .web: return lang == .fr ? "Web" : "Web"
        case .iOS: return lang == .fr ? "app iOS" : "iOS app"
        case .mac: return "Mac"
        }
    }

    var symbol: String {
        switch self {
        case .web: return "globe"
        case .iOS: return "iphone"
        case .mac: return "macbook"
        }
    }

    /// Tone colour for the platform chip.
    var tint: Color {
        switch self {
        case .web: return Color(hex: "#5EEAD4")
        case .iOS: return Color(hex: "#9BB8FF")
        case .mac: return Color(hex: "#C9A24B")
        }
    }
}

// MARK: Theme (the 7 Atelier categories)

enum Theme: String, CaseIterable, Codable, Identifiable {
    case music          // music & ear & instruments
    case film           // film / doc craft
    case writing        // poetry & writing & rhetoric
    case comics         // comics & drawing
    case daily          // daily-delight, local, Moncton, wonder
    case craft          // hands-on craft & making
    case tools          // utilities & meta

    var id: String { rawValue }

    /// Display title for the section header.
    func title(_ lang: Lang) -> String {
        switch self {
        case .music:   return lang == .fr ? "Musique" : "Music"
        case .film:    return lang == .fr ? "Cinéma & doc" : "Film & doc"
        case .writing: return lang == .fr ? "Écriture & poésie" : "Writing & poetry"
        case .comics:  return lang == .fr ? "BD & dessin" : "Comics & drawing"
        case .daily:   return lang == .fr ? "Délices du jour & local" : "Daily delights & local"
        case .craft:   return lang == .fr ? "Métiers & savoir-faire" : "Craft & skills"
        case .tools:   return lang == .fr ? "Outils" : "Tools"
        }
    }

    /// SF Symbol that fronts the section.
    var symbol: String {
        switch self {
        case .music:   return "music.note"
        case .film:    return "film"
        case .writing: return "text.book.closed"
        case .comics:  return "rectangle.split.3x3"
        case .daily:   return "sparkles"
        case .craft:   return "hammer"
        case .tools:   return "wrench.and.screwdriver"
        }
    }

    /// A representative accent for the theme header (a soft tint of its apps).
    var accent: Color {
        switch self {
        case .music:   return Color(hex: "#F2A33C")
        case .film:    return Color(hex: "#E0603A")
        case .writing: return Color(hex: "#B5447A")
        case .comics:  return Color(hex: "#7C3AED")
        case .daily:   return Color(hex: "#E8A13A")
        case .craft:   return Color(hex: "#5A8A6A")
        case .tools:   return Color(hex: "#3F6FB0")
        }
    }
}

// MARK: AppEntry entry

struct AppEntry: Identifiable, Hashable, Codable {
    let id: String          // stable slug — also the widget deep-link key
    let name: String
    let taglineFR: String
    let taglineEN: String
    let platform: Platform
    let url: String?        // web apps only
    let bundleID: String?   // native apps — informational (no launch unless a scheme is known)
    let theme: Theme
    let accentHex: String   // "#RRGGBB"

    // Web initialiser.
    init(_ id: String, _ name: String, _ fr: String, _ en: String,
         web url: String, _ theme: Theme, _ accentHex: String) {
        self.id = id; self.name = name; self.taglineFR = fr; self.taglineEN = en
        self.platform = .web; self.url = url; self.bundleID = nil
        self.theme = theme; self.accentHex = accentHex
    }

    // Native initialiser (iOS or mac).
    init(_ id: String, _ name: String, _ fr: String, _ en: String,
         _ platform: Platform, bundleID: String?, _ theme: Theme, _ accentHex: String) {
        self.id = id; self.name = name; self.taglineFR = fr; self.taglineEN = en
        self.platform = platform; self.url = nil; self.bundleID = bundleID
        self.theme = theme; self.accentHex = accentHex
    }

    func tagline(_ lang: Lang) -> String { lang == .fr ? taglineFR : taglineEN }

    var accent: Color { Color(hex: accentHex) }

    /// First-letter monogram for the tile chip.
    var monogram: String {
        let stripped = name.replacingOccurrences(of: "L'", with: "")
                           .replacingOccurrences(of: "l'", with: "")
        return String(stripped.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }
}

// MARK: The catalog

enum Catalog {
    static let all: [AppEntry] = [

        // MARK: Musique
        AppEntry("la-grille", "La Grille", "Entraîneur Ableton Push — gammes, pads, doigté.",
            "Ableton Push trainer — scales, pads, finger-drumming.",
            web: "https://la-grille.netlify.app", .music, "#3B82F6"),
        AppEntry("le-diapason", "Le Diapason", "Oreille musicale : intervalles, accords, justesse au micro.",
            "Ear training: intervals, chords, mic pitch-matching.",
            web: "https://le-diapason.netlify.app", .music, "#F2A33C"),
        AppEntry("le-baladeur", "Le Baladeur", "Lecteur de balados commandé à la voix.",
            "Voice-commanded podcast player.",
            web: "https://le-baladeur.netlify.app", .music, "#E8612C"),
        AppEntry("ondes", "Ondes", "Musique de concentration à vrais battements binauraux.",
            "Focus music with true binaural beats.",
            web: "https://ondes-app.netlify.app", .music, "#5EEAD4"),
        AppEntry("le-sillon", "Le Sillon", "Une écoute lente, un album par jour.",
            "Slow listening — one album a day.",
            web: "https://le-sillon-app.netlify.app", .music, "#1E3A8A"),
        AppEntry("le-souffleur", "Le Souffleur", "Téléprompteur de chant qui écoute et défile.",
            "Singing teleprompter that listens and scrolls.",
            web: "https://le-souffleur.netlify.app", .music, "#FFC247"),
        AppEntry("letabli", "L'Établi", "Générateur d'accords en boucle pour improviser, hôte AU.",
            "Looping-chord generator to solo over, AU host.",
            .mac, bundleID: "app.atelier.letabli", .music, "#C89B3C"),
        AppEntry("le-souffle", "Le Souffle", "Coach de souffle et de voix (iOS).",
            "Breath & voice warm-up coach (iOS).",
            .iOS, bundleID: "app.atelier.lesouffle", .music, "#5BB5D6"),
        AppEntry("disques-de-chevet", "Disques de Chevet", "Un disque par soir : ta journée devient un album.",
            "One record a night: your day becomes an album.",
            web: "https://disques-de-chevet.netlify.app", .music, "#1E3A8A"),
        AppEntry("eleven-o-clock", "Eleven O'Clock", "Générateur de comédie musicale, ancré dans le métier.",
            "Musical-theatre generator, grounded in the craft.",
            web: "https://eleven-o-clock.netlify.app", .music, "#B5447A"),
        AppEntry("orchestre-de-chambre", "L'Orchestre de Chambre", "Arranger pour petit ensemble, voix par voix.",
            "Arrange for a small ensemble, voice by voice.",
            web: "https://orchestre-de-chambre.netlify.app", .music, "#6D4C9F"),
        AppEntry("la-main-gauche", "La Main Gauche", "Piano jazz, voicing par voicing (ii–V–I, walking bass).",
            "Jazz piano, voicing by voicing (ii–V–I, walking bass).",
            web: "https://la-main-gauche.netlify.app", .music, "#3F6FB0"),
        AppEntry("motif", "Motif", "Un sprint de chanson de 25 min par jour, pont vers Ableton.",
            "A 25-min daily song sprint, bridged to Ableton.",
            web: "https://motif-sprint.netlify.app", .music, "#5EEAD4"),
        AppEntry("room-tone-composer", "Room Tone Composer", "Studio de scènes d'ambiance dans le navigateur.",
            "Browser studio for ambient room-tone scenes.",
            web: "https://room-tone-composer-jac.netlify.app", .music, "#4B7F8C"),
        AppEntry("scene-to-song", "Scene-to-Song", "Transformer une scène en chanson, refrain caché compris.",
            "Turn a scene into a song, hidden hook and all.",
            web: "https://scene-to-song.netlify.app", .music, "#A83A6A"),
        AppEntry("wide-open", "Wide Open", "Explorateur d'accordages alternatifs à la guitare.",
            "Alternate guitar-tuning explorer.",
            web: "https://wide-open-guitar.netlify.app", .music, "#C2742C"),
        AppEntry("la-boucle", "La Boucle", "Boucleur d'apprentissage à l'oreille, étirement sans pitch.",
            "Ear-learning practice looper, pitch-locked time-stretch.",
            web: "https://la-boucle.netlify.app", .music, "#E8612C"),
        AppEntry("les-ondes", "Les Ondes", "Lecteur de radio internet compact, recherche + VU-mètre.",
            "Compact internet-radio player, strong search + VU meter.",
            web: "https://les-ondes.netlify.app", .music, "#2DA6A0"),
        AppEntry("l-accordeur", "L'Accordeur", "Accordeur stroboscopique de précision pour la guitare.",
            "Precision strobe tuner for guitar.",
            .mac, bundleID: "app.atelier.laccordeur", .music, "#F2A33C"),
        AppEntry("le-tintamarre", "Le Tintamarre", "Composer et déclencher un tintamarre acadien (iOS).",
            "Compose and unleash an Acadian tintamarre (iOS).",
            .iOS, bundleID: "app.atelier.letintamarre", .music, "#E8612C"),

        // MARK: Cinéma & doc
        AppEntry("le-cadre", "Le Cadre", "Entraîneur de composition cinématographique.",
            "Cinematic composition trainer.",
            web: "https://le-cadre.netlify.app", .film, "#E5A33B"),
        AppEntry("la-chambre", "La Chambre", "Salle des scénaristes assistée par l'IA.",
            "AI screenwriting writers' room.",
            web: "https://la-chambre.netlify.app", .film, "#B5895A"),
        AppEntry("le-generique", "Le Générique", "Studio de génériques et cartons-titres animés.",
            "Title-sequence & title-card studio.",
            web: "https://le-generique.netlify.app", .film, "#E0603A"),
        AppEntry("l-entretien", "L'Entretien", "Architecte d'entretien documentaire + compagnon de tournage.",
            "Documentary interview architect + on-set companion.",
            web: "https://entretien-doc.netlify.app", .film, "#C8A24A"),
        AppEntry("le-releve", "Le Relevé", "Vos dépenses en budget de tournage.",
            "Your spending mapped to a film budget.",
            web: "https://le-releve.netlify.app", .film, "#1E5C3A"),
        AppEntry("film-grammar", "Film Grammar", "Langage du cinéma : schémas, prose, répétition espacée.",
            "Film language: diagrams, prose, spaced repetition.",
            web: "https://film-grammar.netlify.app", .film, "#C8A24A"),

        // MARK: Écriture & poésie
        AppEntry("le-metier", "Le Métier", "Abécédaire de la poésie, une forme par jour, scansion live.",
            "Poetry primer, a form a day with live scansion.",
            web: "https://le-metier.netlify.app", .writing, "#7A2E2E"),
        AppEntry("la-suite", "La Suite", "Long poème composé section par section.",
            "Longform poem built section by section.",
            web: "https://la-suite-app.netlify.app", .writing, "#1E3A8A"),
        AppEntry("caractere", "Caractère", "Studio d'appariement typographique par l'IA.",
            "AI type-pairing studio.",
            web: "https://caractere.netlify.app", .writing, "#D8412A"),
        AppEntry("le-banquet", "Le Banquet", "Les philosophes racontent, dans leur propre voix.",
            "Philosophers tell their story in their own voice.",
            web: "https://le-banquet-atelier.netlify.app", .writing, "#1F5FA6"),
        AppEntry("le-palais", "Le Palais", "Dojo de la mémoire : loci, système majeur, SRS.",
            "Memory dojo: loci, major system, SRS.",
            web: "https://le-palais-atelier.netlify.app", .writing, "#C9A24B"),
        AppEntry("courtroom-of-ideas", "Courtroom of Ideas", "Mettre une grande idée en procès, pour et contre.",
            "Put a big idea on trial, for and against.",
            web: "https://courtroom-of-ideas.netlify.app", .writing, "#7A2E2E"),
        AppEntry("family-lore", "Family Lore", "Archive vivante de l'héritage : voix, histoires, objets.",
            "A living archive of legacy: voices, stories, objects.",
            web: "https://family-lore.netlify.app", .writing, "#8A5A3C"),
        AppEntry("historical-group-chat", "Historical Group Chat", "Des figures historiques débattent en clavardage.",
            "Historical figures debate in a group chat.",
            web: "https://historical-group-chat.netlify.app", .writing, "#4A6FA8"),
        AppEntry("la-causerie", "La Causerie", "Souper et converser avec un grand esprit du passé.",
            "Dine and talk with a great mind of the past.",
            web: "https://la-causerie.netlify.app", .writing, "#1F5FA6"),
        AppEntry("la-trame", "La Trame", "Apprendre une langue happé par une histoire à suivre.",
            "Learn a language pulled along by a story.",
            web: "https://la-trame.netlify.app", .writing, "#3F7A5A"),
        AppEntry("le-cancre", "Le Cancre", "Apprendre en expliquant à un cancre (méthode Feynman).",
            "Learn by explaining to a dunce (the Feynman technique).",
            web: "https://le-cancre.netlify.app", .writing, "#C9772C"),
        AppEntry("le-carambolage", "Le Carambolage", "Collisions créatives : faire entrechoquer deux idées.",
            "Creative collisions: smash two ideas together.",
            web: "https://le-carambolage.netlify.app", .writing, "#D6382F"),
        AppEntry("le-mot-valise", "Le Mot-Valise", "Fabriquer des mots-valises, dictionnaire de l'imaginaire.",
            "Coin portmanteaus, the dictionary of the imaginary.",
            web: "https://le-mot-valise.netlify.app", .writing, "#7C3AED"),
        AppEntry("le-quartier", "Le Quartier", "Pratiquer une langue à voix haute, en immersion.",
            "Practise a language out loud, fully immersed.",
            web: "https://le-quartier-app.netlify.app", .writing, "#2E8B7A"),
        AppEntry("writers-room", "The Writers' Room", "Six collaborateurs créatifs dans un seul chat.",
            "Six creative collaborators in one chat.",
            web: "https://writers-room-jac.netlify.app", .writing, "#B5895A"),
        AppEntry("la-dispute", "La Dispute", "Le gym de tes convictions : Claude défend l'inverse.",
            "A gym for your convictions: Claude argues the opposite.",
            web: "https://la-dispute.netlify.app", .writing, "#C0392B"),
        AppEntry("la-contrainte", "La Contrainte", "Générateur de contraintes oulipiennes, avec carnet de bord.",
            "Oulipo constraint generator, with a logbook.",
            web: "https://la-contrainte.netlify.app", .writing, "#5A4FCF"),
        AppEntry("le-feuillet", "Le Feuillet", "Éditeur WYSIWYG serein, publie en HTML autonome.",
            "Calm WYSIWYG editor, publishes standalone HTML.",
            web: "https://le-feuillet.netlify.app", .writing, "#3A7A6A"),
        AppEntry("le-volet", "Le Volet", "Écriture sans distraction : le « volet » tamise tout le reste.",
            "Distraction-free writing: the shutter dims all else.",
            .mac, bundleID: "com.jac.LeVolet", .writing, "#46506A"),
        AppEntry("le-complot", "Le Complot", "Tableau de complot à la ficelle rouge : glisse les cartes, la laine suit, exporte en PNG.",
            "Red-string conspiracy board: drag the cards, the yarn follows, export to PNG.",
            web: "https://le-complot.netlify.app", .writing, "#A8472E"),
        AppEntry("la-vanne", "La Vanne", "S'entraîner à écrire des blagues : leçons, salle d'humoristes IA, scène de 60 s avec chahuteur.",
            "Joke-writing practice: lessons, an AI comedy room, a 60-s heckler set.",
            web: "https://la-vanne.netlify.app", .writing, "#D8412A"),
        AppEntry("amorce", "Amorce", "Un pomodoro qui s'ouvre sur un court poème, allumé par ton journal de la veille (iOS).",
            "A pomodoro that opens on a short poem, lit by last night's journal (iOS).",
            .iOS, bundleID: "app.atelier.amorce", .writing, "#7A2E2E"),
        AppEntry("le-bout-de-la-langue", "Le Bout de la langue", "Dictionnaire inversé natif (⌥⌘D) : Claude retrouve le mot sur le bout de la langue, FR↔EN.",
            "Native reverse dictionary (⌥⌘D): Claude finds the word on the tip of your tongue, FR↔EN.",
            .mac, bundleID: "app.atelier.botdelalangue", .writing, "#5A4FCF"),

        // MARK: BD & dessin
        AppEntry("planche", "Planche", "Scène → planche de BD + découpage de plans.",
            "Scene → comic page + film shot list.",
            web: "https://planche-bd.netlify.app", .comics, "#E11D2A"),
        AppEntry("liseuse", "Liseuse", "Lecteur de BD pour les histoires de Planche.",
            "Comic reader for Planche stories.",
            web: "https://liseuse-bd.netlify.app", .comics, "#7C3AED"),
        AppEntry("grammaire-de-la-case", "Grammaire de la case", "Six leçons interactives à la McCloud.",
            "Six interactive McCloud comic-craft lessons.",
            web: "https://grammaire-de-la-case.netlify.app", .comics, "#1D4ED8"),
        AppEntry("l-exquis", "L'Exquis", "Cadavre exquis en dessin, solo ou à plusieurs.",
            "Exquisite-corpse drawing game, solo or pass-and-play.",
            web: "https://l-exquis.netlify.app", .comics, "#D6382F"),
        AppEntry("le-croquis", "Le Croquis", "Pratique quotidienne du dessin de geste, minutée.",
            "Daily timed gesture-drawing practice.",
            web: "https://le-croquis.netlify.app", .comics, "#A8472E"),
        AppEntry("le-calepin", "Le Calepin", "Entraîneur de sketchnoting : pensée visuelle.",
            "Sketchnoting / visual-note trainer.",
            web: "https://le-calepin.netlify.app", .comics, "#1B5BA6"),
        AppEntry("fog", "fog", "Lecture lente : les poèmes émergent du brouillard.",
            "Slow reading: poems emerge from the fog as you scroll.",
            web: "https://fog-poems.netlify.app", .comics, "#6B7C8C"),
        AppEntry("le-kaleidoscope", "Le Kaléidoscope", "Dessin à symétrie générative, comme un kaléidoscope.",
            "Generative-symmetry drawing toy.",
            web: "https://le-kaleidoscope.netlify.app", .comics, "#9B4DCA"),

        // MARK: Délices du jour & local
        AppEntry("la-girouette", "La Girouette", "La météo avec une attitude, en acadien.",
            "Weather with attitude, Acadian voice.",
            web: "https://la-girouette.netlify.app", .daily, "#E8A13A"),
        AppEntry("le-babillard", "Le Babillard", "Tableau des événements du Grand Moncton.",
            "Greater Moncton events board.",
            web: "https://le-babillard.netlify.app", .daily, "#1B5BA6"),
        AppEntry("l-echappee", "L'Échappée", "Moteur de défis et de sérendipité.",
            "Serendipity & dare engine.",
            web: "https://l-echappee.netlify.app", .daily, "#E11D5A"),
        AppEntry("le-vertige", "Le Vertige", "Moteur de découverte de l'émerveillement.",
            "Awe-discovery engine.",
            web: "https://le-vertige.netlify.app", .daily, "#4338CA"),
        AppEntry("petits-saints", "Petits Saints", "Canonisations oubliées, une par jour.",
            "Forgotten canonizations, one a day.",
            web: "https://canonisations.netlify.app", .daily, "#B08D3C"),
        AppEntry("l-atlas", "L'Atlas", "L'histoire du monde en carte vivante.",
            "World history as a living map.",
            web: "https://l-atlas.netlify.app", .daily, "#3B6B4A"),
        AppEntry("chronique", "Chronique", "Quiz quotidien d'histoire : situer les grands tournants.",
            "Daily history quiz: place the great turning points.",
            web: "https://chronique-history-quiz.netlify.app", .daily, "#B08D3C"),
        AppEntry("galerie", "Galerie", "Quiz quotidien de peinture : entraîner l'œil.",
            "Daily painting quiz: train your eye.",
            web: "https://galerie-art-quiz.netlify.app", .daily, "#C9572C"),
        AppEntry("l-almanach", "L'Almanach", "L'almanach poétique de l'année : micro-saison, lune, floraisons.",
            "A poetic almanac of the turning year.",
            web: "https://l-almanach.netlify.app", .daily, "#6E8B3D"),
        AppEntry("la-fenetre", "La Fenêtre", "Trois minutes immergé dans un lieu et une époque.",
            "Three minutes immersed in a place and time.",
            web: "https://la-fenetre.netlify.app", .daily, "#3A6B8A"),
        AppEntry("le-onze", "Le Onze", "Suivre et comprendre la Coupe du monde 2026, décodée.",
            "Follow and decode the 2026 World Cup.",
            web: "https://le-onze-app.netlify.app", .daily, "#2E9E5B"),
        AppEntry("le-portique", "Le Portique", "S'exercer au stoïcisme chaque jour, matin et soir.",
            "Practise Stoicism daily, morning and evening.",
            web: "https://le-portique.netlify.app", .daily, "#7A6A52"),
        AppEntry("le-regal", "Le Régal", "Un régal par jour, tous domaines, avec le pourquoi.",
            "One exquisite thing a day, with the why.",
            web: "https://le-regal-app.netlify.app", .daily, "#C2455A"),
        AppEntry("local-signal", "Local Signal", "Radar culturel bilingue du Grand Moncton.",
            "Bilingual cultural radar for Greater Moncton.",
            web: "https://local-signal-moncton.netlify.app", .daily, "#1B5BA6"),
        AppEntry("sablier", "Sablier", "Méditer sur le temps : sa vie en semaines, une carte par jour.",
            "Meditate on time: your life in weeks, a card a day.",
            web: "https://sablier-app.netlify.app", .daily, "#B8893C"),
        AppEntry("l-air-du-temps", "L'Air du temps", "Décrypteur de tendances et de mèmes, lentille québécoise.",
            "Culture & meme-trend explainer, Québec lens.",
            web: "https://l-air-du-temps.netlify.app", .daily, "#E11D5A"),
        AppEntry("le-galet", "Le Galet", "Affichage familial serein : photos, citations, rappels en fondu.",
            "Calm family display: photos, quotes, reminders that drift.",
            web: "https://le-galet.netlify.app", .daily, "#C9A24B"),
        AppEntry("la-quietude", "La Quiétude", "Méditations guidées à voix neuronale, et un mode libre.",
            "Guided meditations in a neural voice, plus a live mode.",
            web: "https://la-quietude.netlify.app", .daily, "#4C6FA8"),
        AppEntry("pareidolia", "Pareidolia", "Pointe la caméra sur les nuages, Claude y trouve des créatures.",
            "Point the camera at clouds; Claude finds creatures.",
            .iOS, bundleID: "app.atelier.pareidolia", .daily, "#7C9ED6"),
        AppEntry("la-berceuse", "La Berceuse", "Instrument de sommeil : souffle, brassage cognitif, NSDR.",
            "Sleep instrument: breath pacer, cognitive shuffle, NSDR.",
            .iOS, bundleID: "app.atelier.laberceuse", .daily, "#3B4A7A"),
        AppEntry("le-mentaliste", "Le Mentaliste", "Apprendre et exécuter du vrai mentalisme (iOS) : forces, équivoque, lecture à froid, hors ligne.",
            "Learn and perform real mentalism (iOS): forces, equivoque, cold reading, offline.",
            .iOS, bundleID: "app.atelier.lementaliste", .daily, "#6D4C9F"),

        // MARK: Métiers & savoir-faire
        AppEntry("la-saignee", "La Saignée", "Traqueur d'abonnements — « le saignement ».",
            "Subscription tracker — \"the bleed\".",
            web: "https://la-saignee.netlify.app", .craft, "#C0392B"),
        AppEntry("le-poincon", "Le Poinçon", "Forge d'icônes et de jeux d'icônes.",
            "Icon designer & icon-set forge.",
            web: "https://le-poincon.netlify.app", .craft, "#C9A24B"),
        AppEntry("l-empan", "L'Empan", "Entraîneur de lecture rapide (RSVP, empan).",
            "Speed-reading trainer (RSVP, span).",
            web: "https://l-empan.netlify.app", .craft, "#C6F432"),
        AppEntry("apogee", "Apogée", "Constructeur de fusées + simulateur de lancement.",
            "Rocket builder + launch simulator.",
            web: "https://apogee-app.netlify.app", .craft, "#3BF5A0"),
        AppEntry("lavis", "Lavis", "Professeur d'aquarelle, technique par technique.",
            "Watercolour teacher, technique by technique.",
            web: "https://lavis-atelier.netlify.app", .craft, "#4C6FA8"),
        AppEntry("le-penchant", "Le Penchant", "Choisisseur de passe-temps qui plaide sa cause.",
            "Hobby-chooser that argues why it fits you.",
            web: "https://le-penchant-atelier.netlify.app", .craft, "#7A2E2E"),
        AppEntry("le-tour-de-main", "Le Tour de main", "Entraîneur de techniques de cuisine.",
            "Cooking-technique trainer.",
            web: "https://le-tour-de-main-atelier.netlify.app", .craft, "#7A3520"),
        AppEntry("le-rabot", "Le Rabot", "Entraîneur de menuiserie à main : assemblages.",
            "Hand-tool woodworking joinery trainer.",
            web: "https://le-rabot.netlify.app", .craft, "#5A3A22"),
        AppEntry("l-apero", "L'Apéro", "Mixologie zéro alcool, le 5 à 7 sans alcool.",
            "Zero-proof mixology, the alcohol-free 5-à-7.",
            web: "https://l-apero.netlify.app", .craft, "#7DD957"),
        AppEntry("le-pli", "Le Pli", "Entraîneur d'origami, pli par pli.",
            "Origami fold-along trainer.",
            web: "https://le-pli.netlify.app", .craft, "#C0392B"),
        AppEntry("le-cartographe", "Le Cartographe", "Designer de cartes illustrées souvenirs.",
            "Illustrated keepsake-map designer.",
            web: "https://le-cartographe.netlify.app", .craft, "#3A7A6A"),
        AppEntry("l-engrenage", "L'Engrenage", "Bâtir des machines de Rube Goldberg dans un atelier fou.",
            "Build Rube Goldberg machines in a mad workshop.",
            web: "https://l-engrenage.netlify.app", .craft, "#C97A2C"),
        AppEntry("la-maquette", "La Maquette", "Studio de modèles 3D prêts à imprimer.",
            "A studio of print-ready 3D models.",
            web: "https://la-maquette-app.netlify.app", .craft, "#4C7FA8"),
        AppEntry("le-geste-lent", "Le Geste Lent", "Professeur de tai-chi lent, diagrammes scrubables, forme haptique.",
            "Slow tai-chi tutor, scrubbable limb diagrams, haptic form.",
            web: "https://le-geste-lent.netlify.app", .craft, "#5A8A6A"),
        AppEntry("l-aplomb", "L'Aplomb", "Veille de posture sur l'appareil, métaphore du fil à plomb.",
            "On-device posture watcher, a plumb-line metaphor.",
            web: "https://l-aplomb.netlify.app", .craft, "#C6F432"),
        AppEntry("le-pochoir", "Le Pochoir", "Photo → pochoir deux tons prêt à découper, ponts garantis.",
            "Photo → cut-ready two-tone stencil, bridges guaranteed.",
            .mac, bundleID: "app.atelier.lepochoir", .craft, "#3A3A3A"),

        // MARK: Outils & natif
        AppEntry("prise", "Prise", "Pomodoro de la barre des menus, thème montage.",
            "Menu-bar Pomodoro, film-editing themed.",
            .mac, bundleID: "app.atelier.prise", .tools, "#F2A623"),
        AppEntry("nuancier", "Nuancier", "Nuancier de couleurs en éventail.",
            "Colour-palette fan deck.",
            web: "https://nuancier-app.netlify.app", .tools, "#E0603A"),
        AppEntry("trace", "Tracé", "Concepteur de parcours de course → GPX / montre.",
            "Running-route designer → GPX / watch.",
            web: "https://trace-atelier.netlify.app", .tools, "#E2603A"),
        AppEntry("cabri", "Cabri", "Traqueur de squats et de sauts, gamifié (iOS + Watch).",
            "Gamified squat & jump tracker (iOS + Watch).",
            .iOS, bundleID: "app.atelier.cabri", .tools, "#34C759"),
        AppEntry("le-jacquet", "Le Jacquet", "Backgammon contre l'app ou à deux, avec conseils.",
            "Backgammon vs app or two-player, with coaching.",
            web: "https://le-jacquet.netlify.app", .tools, "#C8A24A"),
        AppEntry("la-pepiniere", "La Pépinière", "Faire germer la prochaine appli de l'Atelier.",
            "Germinate the Atelier's next app.",
            web: "https://la-pepiniere.netlify.app", .tools, "#3F8A5A"),
        AppEntry("le-fil-dariane", "Le Fil d'Ariane", "Retrouver le fil d'un projet pour ne jamais se perdre.",
            "Find a project's thread so you never get lost.",
            web: "https://le-fil-dariane.netlify.app", .tools, "#C9A24B"),
        AppEntry("le-limier", "Le Limier", "Enquêter sur ses signets X et en recevoir un breffage.",
            "Investigate your X bookmarks, get a briefing.",
            web: "https://le-limier.netlify.app", .tools, "#7A6A52"),
        AppEntry("less-of-me-to-love", "Less of Me to Love", "Imputabilité à deux : bilans du soir, rappels de pesée.",
            "Two-person accountability: evening check-ins, weigh-in nudges.",
            web: "https://less-of-me-to-love.netlify.app", .tools, "#C0573A"),
        AppEntry("memory-pins", "Memory Pins", "Épingler notes vocales, photos et messages à des lieux réels.",
            "Pin voice notes, photos and messages to real places.",
            web: "https://memory-pins.netlify.app", .tools, "#3A7A6A"),
        AppEntry("mood-budget", "Mood Budget", "Un agenda qui répartit ton énergie, pas tes heures.",
            "A planner that budgets your energy, not your hours.",
            web: "https://mood-budget.netlify.app", .tools, "#8A5AC2"),
        AppEntry("pindrop", "Pindrop", "Compagnon de Memory Pins : scanne un lieu, retrouve l'histoire.",
            "Memory Pins companion: scan a place, find the story.",
            web: "https://pindrop-905.netlify.app", .tools, "#E0603A"),
        AppEntry("la-steno", "La Sténo", "Transcription FR/EN dans le navigateur, SRT/VTT/MD.",
            "In-browser FR/EN transcription, SRT/VTT/MD export.",
            web: "https://la-steno.netlify.app", .tools, "#3F6FB0"),
        AppEntry("darwin", "Darwin", "Client Gmail natif, tri IA Opus, raccourcis clavier.",
            "Native Gmail client, Opus AI triage, keyboard shortcuts.",
            .mac, bundleID: "com.jacquesgautreau.darwin", .tools, "#D44638"),
        AppEntry("l-equerre", "L'Équerre", "Gestionnaire de fenêtres de la barre des menus, grille 12 col.",
            "Menu-bar window manager, 12-column smart grid.",
            .mac, bundleID: "app.atelier.lequerre", .tools, "#2C7A7B"),
        AppEntry("l-horizon", "L'Horizon", "Planificateur d'objectifs long terme, 5 lignes d'horizon.",
            "Long-term goal planner, five horizon lanes.",
            .mac, bundleID: "app.atelier.lhorizon", .tools, "#3B6B9A"),
        AppEntry("le-trombone", "Le Trombone", "Gestionnaire de presse-papiers convoqué au clavier (⌃⇧V).",
            "Keyboard-summoned clipboard manager (⌃⇧V).",
            .mac, bundleID: "com.jac.LeTrombone", .tools, "#C9A24B"),
        AppEntry("punaise", "Punaise", "Note flottante + raccourcis de bouts de texte, sync iCloud.",
            "Floating note + snippet hotkeys, iCloud sync.",
            .mac, bundleID: "com.jac.Punaise", .tools, "#E0603A"),
        AppEntry("le-seuil", "Le Seuil", "Pré-mortem de décision (⌃⌥⌘T) qui revient 90 jours plus tard.",
            "Decision pre-mortem (⌃⌥⌘T) that resurfaces in 90 days.",
            .mac, bundleID: "app.atelier.leseuil", .tools, "#7A2E2E"),
        AppEntry("topo", "Topo", "Compagnon iOS de résumés de balados : marque un moment, distille l'idée.",
            "iOS podcast-summary companion: mark a moment, distil the idea.",
            .iOS, bundleID: "com.jac.Topo", .tools, "#3A7A6A"),
        AppEntry("la-regie", "La Régie", "Orchestrer le contexte du Mac d'un raccourci : un « décor » lance les apps, règle l'audio, change le fond d'écran.",
            "Orchestrate your Mac's context from a hotkey: a \"scene\" launches apps, sets audio, swaps the wallpaper.",
            .mac, bundleID: "app.atelier.laregie", .tools, "#7A6A52"),
    ]

    // MARK: Derived helpers

    /// Apps for a theme, in declared order.
    static func apps(in theme: Theme) -> [AppEntry] { all.filter { $0.theme == theme } }

    /// Themes that actually contain at least one app, in canonical order.
    static var themesInUse: [Theme] { Theme.allCases.filter { !apps(in: $0).isEmpty } }

    /// Look an app up by its slug (used by the widget deep link).
    static func app(id: String) -> AppEntry? { all.first { $0.id == id } }

    static var webCount: Int { all.filter { $0.platform == .web }.count }
    static var iosCount: Int { all.filter { $0.platform == .iOS }.count }
    static var macCount: Int { all.filter { $0.platform == .mac }.count }

    // MARK: Délice du jour — deterministic daily pick (FNV-1a of yyyy-MM-dd)

    /// Same calendar day → same pick, in the app and in the widget. Hashing the
    /// yyyy-MM-dd string (FNV-1a) keeps it stable across launches and devices.
    static func deliceIndex(for date: Date = Date()) -> Int {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        return deliceIndex(forKey: fmt.string(from: date))
    }

    /// The pure, testable core: hash an arbitrary yyyy-MM-dd key.
    static func deliceIndex(forKey key: String) -> Int {
        var h: UInt64 = 1469598103934665603 // FNV-1a offset basis
        for b in key.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Int(h % UInt64(all.count))
    }

    static func delice(for date: Date = Date()) -> AppEntry { all[deliceIndex(for: date)] }

    // MARK: Search — diacritic-insensitive, AND-matched fuzzy filter

    static func search(_ query: String, lang: Lang = .fr) -> [AppEntry] {
        let q = query.folding(options: .diacriticInsensitive, locale: .current)
                     .lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        let terms = q.split(separator: " ").map(String.init)
        return all.filter { app in
            let hay = [app.name, app.taglineFR, app.taglineEN,
                       app.theme.title(.fr), app.theme.title(.en)]
                .joined(separator: " ")
                .folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
            return terms.allSatisfy { hay.contains($0) }
        }
    }
}

// MARK: - Color(hex:) — shared helper

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b: Double
        if s.count == 6 {
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double(v & 0x0000FF) / 255
        } else {
            r = 0; g = 0; b = 0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
