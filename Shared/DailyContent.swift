import Foundation

/// Verse, hadith and dua of the day. The list rotates by day of year.
/// The texts are short renderings of the meaning; have them reviewed (e.g. by a religious official) before release
/// and extend the lists with reviewed content in later updates.
struct ContentItem: Identifiable, Hashable {
    enum Kind: String { case ayet, hadis, dua }
    let id: String
    let kind: Kind
    let text: [String: String]       // tr / en / de
    let source: [String: String]
    let translit: String?            // for duas: transliteration of the Arabic

    var localizedText: String { text[Loc.activeLanguage] ?? text["en"] ?? "" }
    var localizedSource: String { source[Loc.activeLanguage] ?? source["en"] ?? "" }

    var labelKey: String {
        switch kind {
        case .ayet: return "GÜNÜN AYETİ"
        case .hadis: return "GÜNÜN HADİSİ"
        case .dua: return "GÜNÜN DUASI"
        }
    }
}

enum DailyContent {
    static func item(_ kind: ContentItem.Kind, for date: Date = Date()) -> ContentItem {
        let list = all.filter { $0.kind == kind }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return list[(day - 1) % list.count]
    }

    static func today(_ date: Date = Date()) -> [ContentItem] {
        [item(.ayet, for: date), item(.hadis, for: date), item(.dua, for: date)]
    }

    private static func make(_ id: String, _ kind: ContentItem.Kind, tr: String, en: String, de: String,
                             src: (String, String, String), translit: String? = nil) -> ContentItem {
        ContentItem(id: id, kind: kind, text: ["tr": tr, "en": en, "de": de],
                    source: ["tr": src.0, "en": src.1, "de": src.2], translit: translit)
    }

    static let all: [ContentItem] = [
        // MARK: Verses
        make("a1", .ayet,
             tr: "Şüphesiz zorlukla beraber bir kolaylık vardır. Gerçekten zorlukla beraber bir kolaylık vardır.",
             en: "So surely with hardship comes ease. Surely with hardship comes ease.",
             de: "Wahrlich, mit der Erschwernis kommt Erleichterung. Wahrlich, mit der Erschwernis kommt Erleichterung.",
             src: ("İnşirah Suresi, 5–6", "Surah Ash-Sharh 94:5–6", "Sure asch-Scharh 94:5–6")),
        make("a2", .ayet,
             tr: "Bilesiniz ki kalpler ancak Allah'ı anmakla huzur bulur.",
             en: "Truly, it is in the remembrance of Allah that hearts find peace.",
             de: "Wahrlich, im Gedenken Allahs finden die Herzen Ruhe.",
             src: ("Ra'd Suresi, 28", "Surah Ar-Ra'd 13:28", "Sure ar-Ra'd 13:28")),
        make("a3", .ayet,
             tr: "Öyleyse beni anın ki ben de sizi anayım. Bana şükredin, nankörlük etmeyin.",
             en: "So remember Me; I will remember you. Be grateful to Me and do not be ungrateful.",
             de: "So gedenkt Meiner, dann gedenke Ich euer. Seid Mir dankbar und seid nicht undankbar.",
             src: ("Bakara Suresi, 152", "Surah Al-Baqarah 2:152", "Sure al-Baqara 2:152")),
        make("a4", .ayet,
             tr: "Ey iman edenler! Sabır ve namazla yardım dileyin. Şüphesiz Allah sabredenlerle beraberdir.",
             en: "O you who believe, seek help through patience and prayer. Indeed, Allah is with the patient.",
             de: "O die ihr glaubt, sucht Hilfe in der Geduld und im Gebet. Wahrlich, Allah ist mit den Geduldigen.",
             src: ("Bakara Suresi, 153", "Surah Al-Baqarah 2:153", "Sure al-Baqara 2:153")),
        make("a5", .ayet,
             tr: "Allah hiç kimseye gücünün yeteceğinden fazlasını yüklemez.",
             en: "Allah does not burden any soul beyond what it can bear.",
             de: "Allah erlegt keiner Seele mehr auf, als sie zu tragen vermag.",
             src: ("Bakara Suresi, 286", "Surah Al-Baqarah 2:286", "Sure al-Baqara 2:286")),
        make("a6", .ayet,
             tr: "Allah'ın rahmetinden ümidinizi kesmeyin. Şüphesiz Allah bütün günahları bağışlar.",
             en: "Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
             de: "Verliert nicht die Hoffnung auf Allahs Barmherzigkeit. Wahrlich, Allah vergibt alle Sünden.",
             src: ("Zümer Suresi, 53", "Surah Az-Zumar 39:53", "Sure az-Zumar 39:53")),
        make("a7", .ayet,
             tr: "Kim Allah'a tevekkül ederse, O ona yeter.",
             en: "Whoever puts their trust in Allah, He is sufficient for them.",
             de: "Wer auf Allah vertraut, dem ist Er genug.",
             src: ("Talâk Suresi, 3", "Surah At-Talaq 65:3", "Sure at-Talaq 65:3")),

        // MARK: Hadith
        make("h1", .hadis,
             tr: "Ameller ancak niyetlere göredir. Herkese ancak niyet ettiği şey vardır.",
             en: "Actions are only by intentions, and every person will have only what they intended.",
             de: "Die Taten sind nur gemäß den Absichten, und jedem steht nur das zu, was er beabsichtigt hat.",
             src: ("Buhârî, Müslim", "Bukhari, Muslim", "Buchari, Muslim")),
        make("h2", .hadis,
             tr: "Kolaylaştırınız, zorlaştırmayınız; müjdeleyiniz, nefret ettirmeyiniz.",
             en: "Make things easy and do not make them difficult; give glad tidings and do not drive people away.",
             de: "Macht es leicht und macht es nicht schwer; verkündet frohe Botschaft und schreckt nicht ab.",
             src: ("Buhârî", "Bukhari", "Buchari")),
        make("h3", .hadis,
             tr: "Müslüman, dilinden ve elinden Müslümanların emin olduğu kimsedir.",
             en: "A Muslim is the one from whose tongue and hand the Muslims are safe.",
             de: "Ein Muslim ist derjenige, vor dessen Zunge und Hand die Muslime sicher sind.",
             src: ("Buhârî, Müslim", "Bukhari, Muslim", "Buchari, Muslim")),
        make("h4", .hadis,
             tr: "Sizin en hayırlınız Kur'an'ı öğrenen ve öğretendir.",
             en: "The best of you are those who learn the Quran and teach it.",
             de: "Die Besten unter euch sind diejenigen, die den Koran lernen und lehren.",
             src: ("Buhârî", "Bukhari", "Buchari")),
        make("h5", .hadis,
             tr: "Temizlik imanın yarısıdır.",
             en: "Purity is half of faith.",
             de: "Reinheit ist die Hälfte des Glaubens.",
             src: ("Müslim", "Muslim", "Muslim")),
        make("h6", .hadis,
             tr: "Sizden biri, kendisi için istediğini kardeşi için de istemedikçe gerçek anlamda iman etmiş olmaz.",
             en: "None of you truly believes until he loves for his brother what he loves for himself.",
             de: "Keiner von euch glaubt wirklich, bis er für seinen Bruder liebt, was er für sich selbst liebt.",
             src: ("Buhârî, Müslim", "Bukhari, Muslim", "Buchari, Muslim")),
        make("h7", .hadis,
             tr: "Güzel söz sadakadır.",
             en: "A good word is charity.",
             de: "Ein gutes Wort ist eine Spende (Sadaqa).",
             src: ("Buhârî, Müslim", "Bukhari, Muslim", "Buchari, Muslim")),

        // MARK: Duas (from the Quran)
        make("d1", .dua,
             tr: "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver ve bizi ateş azabından koru.",
             en: "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
             de: "Unser Herr, gib uns im Diesseits Gutes und im Jenseits Gutes und bewahre uns vor der Strafe des Feuers.",
             src: ("Bakara Suresi, 201", "Surah Al-Baqarah 2:201", "Sure al-Baqara 2:201"),
             translit: "Rabbenâ âtinâ fi'd-dünyâ haseneten ve fi'l-âhireti haseneten ve kınâ azâbe'n-nâr."),
        make("d2", .dua,
             tr: "Rabbim, ilmimi artır.",
             en: "My Lord, increase me in knowledge.",
             de: "Mein Herr, mehre mein Wissen.",
             src: ("Tâhâ Suresi, 114", "Surah Ta-Ha 20:114", "Sure Ta-Ha 20:114"),
             translit: "Rabbi zidnî ilmâ."),
        make("d3", .dua,
             tr: "Rabbimiz! Biz kendimize zulmettik. Eğer bizi bağışlamaz ve bize merhamet etmezsen mutlaka kaybedenlerden oluruz.",
             en: "Our Lord, we have wronged ourselves. If You do not forgive us and have mercy on us, we will surely be among the losers.",
             de: "Unser Herr, wir haben uns selbst Unrecht getan. Wenn Du uns nicht vergibst und Dich unser nicht erbarmst, werden wir gewiss zu den Verlierern gehören.",
             src: ("A'râf Suresi, 23", "Surah Al-A'raf 7:23", "Sure al-A'raf 7:23"),
             translit: "Rabbenâ zalemnâ enfusenâ ve in lem tağfir lenâ ve terhamnâ lenekûnenne mine'l-hâsirîn."),
        make("d4", .dua,
             tr: "Rabbim! Beni ve neslimden gelecekleri namazı devamlı kılanlardan eyle. Rabbimiz! Duamı kabul et.",
             en: "My Lord, make me and my descendants steadfast in prayer. Our Lord, accept my supplication.",
             de: "Mein Herr, lass mich und meine Nachkommen das Gebet beständig verrichten. Unser Herr, nimm mein Bittgebet an.",
             src: ("İbrâhîm Suresi, 40", "Surah Ibrahim 14:40", "Sure Ibrahim 14:40"),
             translit: "Rabbic'alnî mukîme's-salâti ve min zürriyyetî, Rabbenâ ve tekabbel duâ."),
        make("d5", .dua,
             tr: "Rabbimiz! Bizi doğru yola ilettikten sonra kalplerimizi kaydırma. Bize katından bir rahmet bağışla. Şüphesiz sen çok bağışlayansın.",
             en: "Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself. Indeed, You are the Bestower.",
             de: "Unser Herr, lass unsere Herzen nicht abschweifen, nachdem Du uns rechtgeleitet hast, und schenke uns Barmherzigkeit von Dir. Du bist ja der Schenkende.",
             src: ("Âl-i İmrân Suresi, 8", "Surah Al Imran 3:8", "Sure Al Imran 3:8"),
             translit: "Rabbenâ lâ tüziğ kulûbenâ ba'de iz hedeytenâ ve heb lenâ min ledünke rahmeh, inneke ente'l-vehhâb."),
        make("d6", .dua,
             tr: "Rabbimiz! Bize gözümüzü aydınlatacak eşler ve nesiller bağışla ve bizi takva sahiplerine önder kıl.",
             en: "Our Lord, grant us spouses and offspring who are a comfort to our eyes, and make us leaders of the God-fearing.",
             de: "Unser Herr, schenke uns an unseren Gatten und Nachkommen Augentrost und mache uns zu Vorbildern für die Gottesfürchtigen.",
             src: ("Furkan Suresi, 74", "Surah Al-Furqan 25:74", "Sure al-Furqan 25:74"),
             translit: "Rabbenâ heb lenâ min ezvâcinâ ve zürriyyâtinâ kurrate a'yunin vec'alnâ li'l-müttakîne imâmâ."),
        make("d7", .dua,
             tr: "Rabbimiz! Unutur ya da yanılırsak bizi sorumlu tutma.",
             en: "Our Lord, do not take us to task if we forget or make a mistake.",
             de: "Unser Herr, belange uns nicht, wenn wir vergessen oder einen Fehler begehen.",
             src: ("Bakara Suresi, 286", "Surah Al-Baqarah 2:286", "Sure al-Baqara 2:286"),
             translit: "Rabbenâ lâ tüâhiznâ in nesînâ ev ahta'nâ.")
    ]
}
