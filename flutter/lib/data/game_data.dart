// Данные перенесены 1:1 из оригинальных модулей Godot (modules/*.gd).
// Тексты, цены, требования и бонусы не изменены.

final Map<String, dynamic> itemDb = {
  "health_potion": {
    "name": "Зелье здоровья",
    "type": "consumable",
    "level": 1,
    "description": "Восстанавливает 50 HP.",
    "durability": -1,
    "price": 10,
    "requirements": {},
    "bonuses": {"hp_restore": 50},
    "icon": "🧪"
  },
  "iron_sword": {
    "name": "Железный меч",
    "type": "equipment",
    "slot": "weapon",
    "level": 2,
    "description": "Обычный железный меч.",
    "durability": 100,
    "price": 150,
    "requirements": {"strength": 5, "agility": 3},
    "bonuses": {"attack": 12, "crit_chance": 2},
    "icon": "⚔️"
  },
  "steel_sword": {
    "name": "Стальной меч",
    "type": "equipment",
    "slot": "weapon",
    "level": 5,
    "description": "Качественный стальной меч.",
    "durability": 120,
    "price": 300,
    "requirements": {"strength": 10, "agility": 7},
    "bonuses": {"attack": 20, "crit_chance": 4},
    "icon": "⚔️"
  },
  "leather_armor": {
    "name": "Кожаная броня",
    "type": "equipment",
    "slot": "armor",
    "level": 1,
    "description": "Лёгкая броня из кожи.",
    "durability": 80,
    "price": 80,
    "requirements": {"endurance": 3},
    "bonuses": {"defense": 8, "evasion": 2},
    "icon": "🛡️"
  },
  "rat_tail": {
    "name": "Крысиный хвост",
    "type": "material",
    "level": 1,
    "description": "Хвост крысы. Можно продать или использовать в крафте.",
    "durability": -1,
    "price": 5,
    "requirements": {},
    "bonuses": {},
    "icon": "🐀"
  },
  "bone": {
    "name": "Кость",
    "type": "material",
    "level": 1,
    "description": "Кость скелета. Можно продать или использовать в крафте.",
    "durability": -1,
    "price": 8,
    "requirements": {},
    "bonuses": {},
    "icon": "🦴"
  },
  "wolf_fur": {
    "name": "Волчья шкура",
    "type": "material",
    "level": 1,
    "description": "Шкура волка. Можно продать или использовать в крафте.",
    "durability": -1,
    "price": 10,
    "requirements": {},
    "bonuses": {},
    "icon": "🐺"
  },
  "orc_tusk": {
    "name": "Клык орка",
    "type": "material",
    "level": 5,
    "description": "Клык орка. Ценный трофей.",
    "durability": -1,
    "price": 25,
    "requirements": {},
    "bonuses": {},
    "icon": "🦷"
  },
  "ghost_essence": {
    "name": "Призрачная эссенция",
    "type": "material",
    "level": 10,
    "description": "Эссенция призрака. Редкий материал.",
    "durability": -1,
    "price": 50,
    "requirements": {},
    "bonuses": {},
    "icon": "👻"
  },
  "golem_core": {
    "name": "Ядро голема",
    "type": "material",
    "level": 15,
    "description": "Ядро каменного голема. Очень ценный материал.",
    "durability": -1,
    "price": 100,
    "requirements": {},
    "bonuses": {},
    "icon": "🗿"
  },
  "dragon_scale": {
    "name": "Чешуя дракона",
    "type": "material",
    "level": 20,
    "description": "Чешуя дракона. Легендарный материал.",
    "durability": -1,
    "price": 200,
    "requirements": {},
    "bonuses": {},
    "icon": "🐉"
  },
  "demon_heart": {
    "name": "Сердце демона",
    "type": "material",
    "level": 25,
    "description": "Сердце демона. Тёмный артефакт.",
    "durability": -1,
    "price": 300,
    "requirements": {},
    "bonuses": {},
    "icon": "😈"
  }
};

final Map<String, dynamic> shopItems = {
  "iron_sword": {
    "name": "Железный меч",
    "type": "weapon",
    "level": 2,
    "description": "Обычный железный меч.",
    "durability": 100,
    "price_gold": 100,
    "price_rune": 0,
    "rarity": "обычный",
    "requirements": {"strength": 5, "agility": 3},
    "bonuses": {"attack": 10, "crit_chance": 2}
  },
  "steel_sword": {
    "name": "Стальной меч",
    "type": "weapon",
    "level": 4,
    "description": "Качественный стальной меч.",
    "durability": 120,
    "price_gold": 250,
    "price_rune": 0,
    "rarity": "редкий",
    "requirements": {"strength": 8, "agility": 5},
    "bonuses": {"attack": 15, "crit_chance": 3}
  },
  "elite_sword": {
    "name": "Элитный меч",
    "type": "weapon",
    "level": 10,
    "description": "Меч древних героев.",
    "durability": 200,
    "price_gold": 0,
    "price_rune": 100,
    "rarity": "легендарный",
    "requirements": {"strength": 25, "agility": 20},
    "bonuses": {"attack": 50, "crit_chance": 10}
  },
  "health_potion": {
    "name": "Зелье здоровья",
    "type": "consumable",
    "level": 1,
    "description": "Восстанавливает 50 HP.",
    "durability": -1,
    "price_gold": 10,
    "price_rune": 0,
    "rarity": "обычный",
    "requirements": {},
    "bonuses": {"hp_restore": 50}
  },
  "leather_armor": {
    "name": "Кожаная броня",
    "type": "armor",
    "level": 1,
    "description": "Лёгкая броня из кожи.",
    "durability": 80,
    "price_gold": 80,
    "price_rune": 0,
    "rarity": "обычный",
    "requirements": {"endurance": 3},
    "bonuses": {"defense": 8, "evasion": 2}
  }
};

final List<String> marketGreetings = [
  "Добро пожаловать, путник!",
  "Что ищешь сегодня?",
  "Заходи, не стесняйся!",
  "Свежие товары только привезли!"
];

final Map<String, dynamic> auctionItems = {
  "health_potion": {
    "name": "Зелье здоровья",
    "type": "consumable",
    "level": 1,
    "description": "Восстанавливает 50 HP.",
    "lore": "Обычное зелье, которое можно найти в любой лавке. Сварено по стандартному рецепту алхимиков.",
    "durability": -1,
    "price": 10,
    "price_rune": 0,
    "requirements": {},
    "bonuses": {"hp_restore": 50}
  },
  "iron_sword": {
    "name": "Железный меч",
    "type": "equipment",
    "slot": "weapon",
    "level": 2,
    "description": "Обычный железный меч.",
    "lore": "Выкован местным кузнецом. Ничего особенного, но для новичка сойдёт. Говорят, такие мечи делают из руды, добытой в ближайших шахтах.",
    "durability": 100,
    "price": 150,
    "price_rune": 0,
    "requirements": {"strength": 5, "agility": 3},
    "bonuses": {"attack": 12, "crit_chance": 2}
  },
  "steel_sword": {
    "name": "Стальной меч",
    "type": "equipment",
    "slot": "weapon",
    "level": 5,
    "description": "Качественный стальной меч.",
    "lore": "Выкован лучшим кузнецом города. Сталь закалена особым способом, что придаёт мечу небывалую прочность. Такие мечи часто берут с собой в опасные походы.",
    "durability": 120,
    "price": 300,
    "price_rune": 0,
    "requirements": {"strength": 10, "agility": 7},
    "bonuses": {"attack": 20, "crit_chance": 4}
  },
  "leather_armor": {
    "name": "Кожаная броня",
    "type": "equipment",
    "slot": "armor",
    "level": 1,
    "description": "Лёгкая броня из кожи.",
    "lore": "Сшита из шкур диких животных. Обеспечивает неплохую защиту, не сковывая движений. Любимый выбор разбойников и следопытов.",
    "durability": 80,
    "price": 80,
    "price_rune": 0,
    "requirements": {"endurance": 3},
    "bonuses": {"defense": 8, "evasion": 2}
  }
};

final Map<String, dynamic> foodDb = {
  "hot_soup": {
    "name": "Горячая похлёбка",
    "description": "Наваристый суп с мясом и травами. Согревает и бодрит.",
    "price_gold": 10,
    "duration": 1800,
    "buff_type": "exp",
    "buff_value": 10,
    "icon": "🍲"
  },
  "shrimp": {
    "name": "Креветки с чесноком",
    "description": "Сочные креветки, запечённые с чесноком и маслом.",
    "price_gold": 15,
    "duration": 1800,
    "buff_type": "max_hp",
    "buff_value": 15,
    "icon": "🦐"
  },
  "dwarf_ale": {
    "name": "Эль дворфа",
    "description": "Крепкий напиток, сваренный по древнему рецепту.",
    "price_gold": 20,
    "duration": 1800,
    "buff_type": "strength",
    "buff_value": 5,
    "icon": "🍺"
  },
  "vigor_elixir": {
    "name": "Эликсир бодрости",
    "description": "Настой из горных трав придаёт невероятную лёгкость.",
    "price_gold": 25,
    "duration": 1800,
    "buff_type": "speed",
    "buff_value": 10,
    "icon": "🧪"
  },
  "mead": {
    "name": "Медовуха",
    "description": "Сладкий хмельной напиток на мёде и травах.",
    "price_gold": 30,
    "duration": 1800,
    "buff_type": "defense",
    "buff_value": 10,
    "icon": "🍯"
  },
  "gnome_feast": {
    "name": "Пирушка гномов",
    "description": "Гномье застолье с жареным мясом и золотистым элем.",
    "price_gold": 50,
    "duration": 3600,
    "buff_type": "gold",
    "buff_value": 20,
    "icon": "🍖"
  }
};

final Map<String, dynamic> songsDb = {
  "ballad_courage": {
    "name": "Баллада о храбрости",
    "description": "Песнь о древних героях, вселяющая отвагу.",
    "price_gold": 50,
    "duration": 3600,
    "buff_type": "attack",
    "buff_value": 15,
    "icon": "⚔️"
  },
  "elegy_protection": {
    "name": "Элегия защиты",
    "description": "Меланхоличная мелодия, дарующая несокрушимость.",
    "price_gold": 50,
    "duration": 3600,
    "buff_type": "defense",
    "buff_value": 20,
    "icon": "🛡️"
  },
  "lucky_song": {
    "name": "Песня удачи",
    "description": "Весёлая песенка про беззаботного вора.",
    "price_gold": 75,
    "duration": 3600,
    "buff_type": "crit_chance",
    "buff_value": 10,
    "icon": "🍀"
  },
  "ancient_hymn": {
    "name": "Древний гимн",
    "description": "Гимн на забытом языке, открывающий тайны мира.",
    "price_gold": 100,
    "duration": 3600,
    "buff_type": "exp",
    "buff_value": 15,
    "icon": "📜"
  },
  "wind_song": {
    "name": "Песня ветров",
    "description": "Лёгкая мелодия, похожая на шелест крыльев.",
    "price_gold": 75,
    "duration": 3600,
    "buff_type": "evasion",
    "buff_value": 10,
    "icon": "🌬️"
  },
  "restoration_hymn": {
    "name": "Гимн восстановления",
    "description": "Целебная музыка, залечивающая раны.",
    "price_gold": 125,
    "duration": 3600,
    "buff_type": "regen",
    "buff_value": 5,
    "icon": "💚"
  },
  "dragon_song": {
    "name": "Песнь дракона",
    "description": "Древняя песнь, дающая силу огнедышащего зверя.",
    "price_gold": 200,
    "duration": 3600,
    "buff_type": "berserk",
    "buff_value": 25,
    "icon": "🐉"
  }
};

final Map<String, dynamic> strangerRumors = {
  "r1": {"name": "Шёпот в катакомбах", "price": 50, "text": "Под городом есть забытые катакомбы, где обитает нечто древнее. Говорят, там можно найти артефакты павшего ордена.", "icon": "👤"},
  "r2": {"name": "Демонический ритуал", "price": 75, "text": "Барон заключает сделки с демонами по ночам. Из его замка доносятся крики и зелёное пламя.", "icon": "👤"},
  "r3": {"name": "Призрачный рыцарь", "price": 60, "text": "В полночь на старом кладбище появляется призрачный рыцарь. Он ищет своё потерянное копьё.", "icon": "👤"},
  "r4": {"name": "Ночная ведьма", "price": 80, "text": "Говорят, ведьма в лесу может предсказать судьбу за одну руну. Но цена её пророчеств — частичка души.", "icon": "👤"},
  "r5": {"name": "Проклятый театр", "price": 55, "text": "Старый театр заколочен уже 50 лет. Внутри продолжаются представления с участием теней умерших актёров.", "icon": "👤"},
  "r6": {"name": "Культ Чёрного Сердца", "price": 90, "text": "В подземельях гильдии магов собирается культ Чёрного Сердца. Их знак — выжженная ладонь.", "icon": "👤"},
  "r7": {"name": "Вампир в городе", "price": 70, "text": "Среди знати завёлся вампир. Уже три девушки из богатых семей найдены обескровленными.", "icon": "👤"},
  "r8": {"name": "Озеро мёртвых", "price": 85, "text": "Западнее города есть озеро, где вода чёрная как смоль. Рыбаки пропадают там каждую весну.", "icon": "👤"},
  "r9": {"name": "Проклятие оборотня", "price": 65, "text": "Мясник с южной улицы каждое полнолуние превращается в зверя. Он сам не знает об этом.", "icon": "👤"},
  "r10": {"name": "Говорящий череп", "price": 100, "text": "В подвале старой башни хранится череп, который отвечает на вопросы. Каждый ответ отнимает год жизни.", "icon": "👤"},
  "r11": {"name": "Тёмный алтарь", "price": 95, "text": "В чащобе есть алтарь из чёрного камня. Если принести жертву, твоя тень оживёт.", "icon": "👤"},
  "r12": {"name": "Повелитель крыс", "price": 45, "text": "В канализации живёт Король Крыс. Говорят, у него есть кольцо, делающее хозяина невидимым.", "icon": "👤"},
  "r13": {"name": "Проклятое зеркало", "price": 110, "text": "В особняке купца висит зеркало, в котором отражается будущее. Тот, кто посмотрит в него, умрёт в течение года.", "icon": "👤"},
  "r14": {"name": "Некромант-отшельник", "price": 120, "text": "В горах живёт некромант, воскрешающий мёртвых. Он ищет помощника для древнего ритуала.", "icon": "👤"},
  "r15": {"name": "Лес шепчущих", "price": 130, "text": "Глубоко в лесу есть поляна, где деревья растут из человеческих костей. Там можно услышать голоса погибших.", "icon": "👤"}
};

final Map<String, dynamic> guardRumors = {
  "g1": {"name": "Награда за банду", "price": 50, "text": "Лорд-командующий объявил награду в 1000 золотых за голову главаря банды 'Чёрные псы'.", "icon": "🛡️"},
  "g2": {"name": "Горный тролль", "price": 60, "text": "Любой, кто доставит голову горного тролля, получит земли и титул барона.", "icon": "🛡️"},
  "g3": {"name": "Пропавший патруль", "price": 55, "text": "Патрульные пропадают в восточном лесу. Последний дозорный успел прошептать: 'Они движутся под землёй'.", "icon": "🛡️"},
  "g4": {"name": "Караванная дорога", "price": 40, "text": "Купеческая гильдия нанимает охрану для каравана в столицу. Обещают 300 золотых.", "icon": "🛡️"},
  "g5": {"name": "Беглый маг", "price": 70, "text": "Из городской тюрьмы сбежал опасный маг. Награда за поимку — 500 золотых.", "icon": "🛡️"},
  "g6": {"name": "Контрабандисты", "price": 45, "text": "В порту орудует банда контрабандистов. Таможня ищет смельчаков для рейда на склад.", "icon": "🛡️"},
  "g7": {"name": "Странные огни", "price": 65, "text": "В подземельях старой крепости видели странные огни. Капитан стражи предлагает 200 золотых.", "icon": "🛡️"},
  "g8": {"name": "Бешеные волки", "price": 35, "text": "В северном лесу появились бешеные волки-мутанты. Награда за каждого — 50 золотых.", "icon": "🛡️"},
  "g9": {"name": "Похищение детей", "price": 80, "text": "В пригороде пропадают дети. Все улики ведут к старой мельнице.", "icon": "🛡️"},
  "g10": {"name": "Поддельные монеты", "price": 55, "text": "В городе появились фальшивые золотые. Награда 400 золотых за поимку фальшивомонетчиков.", "icon": "🛡️"},
  "g11": {"name": "Запретная книга", "price": 90, "text": "Из библиотеки украдена книга 'Некрономикон'. Награда 1000 золотых.", "icon": "🛡️"},
  "g12": {"name": "Чумной мор", "price": 75, "text": "В трущобах начался мор. Нужны смельчаки, чтобы доставить лекарства.", "icon": "🛡️"},
  "g13": {"name": "Побег из тюрьмы", "price": 85, "text": "Трое опасных преступников сбежали. Награда за каждого — 200 золотых.", "icon": "🛡️"},
  "g14": {"name": "Подземелье гильдии", "price": 95, "text": "Под штабом воровской гильдии есть секретный ход в королевскую казну.", "icon": "🛡️"},
  "g15": {"name": "Говорящий конь", "price": 100, "text": "Король ищет мудреца, который сможет перевести речь его говорящего коня.", "icon": "🛡️"}
};

final Map<String, dynamic> adventurerRumors = {
  "a1": {"name": "Меч первого короля", "price": 200, "text": "Легендарный меч, разрубающий камень, в гробнице первого короля. Вход охраняют каменные големы.", "icon": "🧙"},
  "a2": {"name": "Клад пиратов", "price": 150, "text": "Клад пиратов Золотой Бороды в пустыне. Карта разделена на три части.", "icon": "🧙"},
  "a3": {"name": "Храм Времени", "price": 250, "text": "Древний храм, где можно увидеть прошлое и будущее, но путешественник стареет на 10 лет.", "icon": "🧙"},
  "a4": {"name": "Глаз дракона", "price": 300, "text": "Глаз дракона — артефакт, исполняющий желание. Хранится в гнезде последнего живого дракона.", "icon": "🧙"},
  "a5": {"name": "Остров духов", "price": 180, "text": "За туманами есть остров, где обитают духи предков. Нужно принести жертву.", "icon": "🧙"},
  "a6": {"name": "Амулет тьмы", "price": 220, "text": "Амулет, поглощающий души врагов, разбит на три осколка. Нужно собрать все.", "icon": "🧙"},
  "a7": {"name": "Летающий город", "price": 350, "text": "В небесах парит древний город атлантов. Там хранятся знания богов.", "icon": "🧙"},
  "a8": {"name": "Бессмертный воин", "price": 280, "text": "В горах живёт бессмертный воин, охраняющий врата в ад. Он научит любому оружию.", "icon": "🧙"},
  "a9": {"name": "Чаша Грааля", "price": 500, "text": "Чаша, дающая вечную жизнь, спрятана в замке, который появляется раз в сто лет.", "icon": "🧙"},
  "a10": {"name": "Ключ от всех дверей", "price": 180, "text": "Ключ, открывающий любую дверь, у старого отшельника на вершине горы.", "icon": "🧙"},
  "a11": {"name": "Зеркало истины", "price": 210, "text": "Зеркало, показывающее истинную сущность человека, в заброшенном монастыре.", "icon": "🧙"},
  "a12": {"name": "Книга мёртвых", "price": 400, "text": "Книга, воскрешающая любого, была уничтожена. Осталось три страницы.", "icon": "🧙"},
  "a13": {"name": "Камень судьбы", "price": 320, "text": "Камень, предсказывающий будущее, в храме на вершине вулкана.", "icon": "🧙"},
  "a14": {"name": "Печать древних", "price": 270, "text": "Печать, запечатывающая портал в мир демонов, ослабла. Нужно найти три кристалла.", "icon": "🧙"},
  "a15": {"name": "Венец власти", "price": 450, "text": "Венец, дающий власть над смертными, в гробнице первого императора.", "icon": "🧙"}
};

final Map<String, dynamic> questMobsDb = {
  "rat": {"name": "Крыса", "location": "cave", "location_name": "Пещера", "rank": "F", "level_req": 1, "item": "rat_tail", "item_name": "Крысиный хвост", "icon": "🐀"},
  "skel": {"name": "Скелет", "location": "crypt", "location_name": "Склеп", "rank": "E", "level_req": 5, "item": "bone", "item_name": "Кость", "icon": "💀"},
  "wolf": {"name": "Волк", "location": "dark_forest", "location_name": "Тёмный лес", "rank": "F", "level_req": 1, "item": "wolf_fur", "item_name": "Волчья шкура", "icon": "🐺"},
  "orc": {"name": "Орк", "location": "green_meadow", "location_name": "Зелёные луга", "rank": "D", "level_req": 15, "item": "orc_tusk", "item_name": "Клык орка", "icon": "👹"},
  "ghost": {"name": "Призрак", "location": "old_mansion", "location_name": "Заброшенный особняк", "rank": "C", "level_req": 20, "item": "ghost_essence", "item_name": "Призрачная эссенция", "icon": "👻"},
  "golem": {"name": "Голем", "location": "ruins", "location_name": "Древние руины", "rank": "B", "level_req": 30, "item": "golem_core", "item_name": "Ядро голема", "icon": "🗿"},
  "dragon": {"name": "Дракон", "location": "tower", "location_name": "Башня мага", "rank": "A", "level_req": 40, "item": "dragon_scale", "item_name": "Чешуя дракона", "icon": "🐉"},
  "demon": {"name": "Демон", "location": "castle", "location_name": "Замок", "rank": "S", "level_req": 50, "item": "demon_heart", "item_name": "Сердце демона", "icon": "😈"}
};

final Map<String, dynamic> bossesDungeon = {
  "crypt_king": {
    "name": "Лорд Лич, Пожиратель Душ",
    "icon": "💀",
    "level": 10,
    "hp": 1000,
    "attack_min": 50,
    "attack_max": 80,
    "defense": 40,
    "location": "crypt",
    "location_name": "Склеп",
    "available_duration": 600,
    "description": "Древний правитель мёртвых, восставший из гробницы.",
    "enemies": [
      {"name": "Костяной воин", "level": 5, "damage": "25-40", "icon": "💀", "drops": "Кость"},
      {"name": "Призрачный слуга", "level": 8, "damage": "35-55", "icon": "👻", "drops": "Призрачная пыль"}
    ],
    "rewards": {"exp": 100, "gold": 200, "points": 10},
    "drops": [
      {"item": "lich_crystal", "name": "Лич-кристалл", "chance": 10, "icon": "💎"},
      {"item": "bone_staff", "name": "Костяной посох", "chance": 5, "icon": "🔮"}
    ],
    "rumor": "Говорят, Лич спрятал свою душу в кристалле."
  },
  "tower_guardian": {
    "name": "Страж Забытой Башни",
    "icon": "🗿",
    "level": 20,
    "hp": 2500,
    "attack_min": 70,
    "attack_max": 100,
    "defense": 60,
    "location": "tower",
    "location_name": "Башня",
    "available_duration": 900,
    "description": "Каменный страж, охраняющий древнюю башню.",
    "enemies": [
      {"name": "Каменный солдат", "level": 15, "damage": "40-65", "icon": "🗿", "drops": "Каменное ядро"},
      {"name": "Магический шар", "level": 18, "damage": "55-80", "icon": "🔮", "drops": "Магический кристалл"}
    ],
    "rewards": {"exp": 200, "gold": 400, "points": 20},
    "drops": [
      {"item": "guardian_core", "name": "Ядро стража", "chance": 10, "icon": "⚙️"},
      {"item": "ancient_scroll", "name": "Древний свиток", "chance": 15, "icon": "📜"}
    ],
    "rumor": "Башня хранит тайны древних магов."
  },
  "verdant_wyrm": {
    "name": "Зелёный Змей",
    "icon": "🐉",
    "level": 30,
    "hp": 5000,
    "attack_min": 100,
    "attack_max": 150,
    "defense": 80,
    "location": "forest",
    "location_name": "Лес",
    "available_duration": 1200,
    "description": "Древний змей, опутавший корнями лес.",
    "enemies": [
      {"name": "Лесной змеёныш", "level": 22, "damage": "60-90", "icon": "🐍", "drops": "Змеиная чешуя"},
      {"name": "Древесный дух", "level": 25, "damage": "70-110", "icon": "🌳", "drops": "Древесная сердцевина"}
    ],
    "rewards": {"exp": 300, "gold": 600, "points": 30},
    "drops": [
      {"item": "wyrm_scale", "name": "Чешуя змея", "chance": 15, "icon": "🛡️"},
      {"item": "wyrm_heart", "name": "Сердце змея", "chance": 8, "icon": "❤️"}
    ],
    "rumor": "Змей охраняет древо жизни."
  },
  "magma_behemoth": {
    "name": "Повелитель Магмы, Сердце Вулкана",
    "icon": "🔥",
    "level": 40,
    "hp": 8000,
    "attack_min": 120,
    "attack_max": 180,
    "defense": 100,
    "location": "volcano",
    "location_name": "Вулкан",
    "available_duration": 1500,
    "description": "Гигантское существо из лавы и камня.",
    "enemies": [
      {"name": "Лавовый слизень", "level": 30, "damage": "80-120", "icon": "🟠", "drops": "Кусок лавы"},
      {"name": "Огненный дух", "level": 35, "damage": "100-150", "icon": "🔥", "drops": "Искра пламени"}
    ],
    "rewards": {"exp": 500, "gold": 1000, "points": 50},
    "drops": [
      {"item": "magma_heart", "name": "Сердце магмы", "chance": 8, "icon": "❤️"},
      {"item": "lava_sword", "name": "Лавовый клинок", "chance": 10, "icon": "⚔️"}
    ],
    "rumor": "Бегемот куёт оружие в лаве."
  },
  "shadow_wraith": {
    "name": "Теневой Убийца, Дух Тьмы",
    "icon": "👤",
    "level": 50,
    "hp": 12000,
    "attack_min": 150,
    "attack_max": 220,
    "defense": 120,
    "location": "castle",
    "location_name": "Замок",
    "available_duration": 1800,
    "description": "Бестелесное существо из чистой тьмы.",
    "enemies": [
      {"name": "Теневой сгусток", "level": 40, "damage": "100-150", "icon": "⬛", "drops": "Осколок тьмы"},
      {"name": "Тёмный дух", "level": 45, "damage": "120-170", "icon": "🌑", "drops": "Тёмная эссенция"}
    ],
    "rewards": {"exp": 800, "gold": 1500, "points": 80},
    "drops": [
      {"item": "shadow_sword", "name": "Теневой меч", "chance": 8, "icon": "⚔️"},
      {"item": "shadow_crystal", "name": "Теневой кристалл", "chance": 5, "icon": "💎"}
    ],
    "rumor": "Призрак собирает тени павших."
  },
  "frost_drake": {
    "name": "Ледяной Дрейк, Хранитель Вечного Холода",
    "icon": "❄️",
    "level": 60,
    "hp": 20000,
    "attack_min": 200,
    "attack_max": 300,
    "defense": 150,
    "location": "ruins",
    "location_name": "Руины",
    "available_duration": 2400,
    "description": "Древний дракон, покрытый вечным льдом.",
    "enemies": [
      {"name": "Ледяной дракончик", "level": 50, "damage": "120-180", "icon": "🐉", "drops": "Ледяная чешуя"},
      {"name": "Снежный элементаль", "level": 55, "damage": "150-220", "icon": "❄️", "drops": "Снежный кристалл"}
    ],
    "rewards": {"exp": 1200, "gold": 2500, "points": 120},
    "drops": [
      {"item": "drake_bone", "name": "Кость дрейка", "chance": 15, "icon": "🦴"},
      {"item": "ice_essence", "name": "Ледяная эссенция", "chance": 10, "icon": "💠"}
    ],
    "rumor": "Дрейк хранит древний ледяной артефакт."
  }
};

final Map<String, dynamic> bossesWorld = {
  "ancient_dragon": {
    "name": "Древний Дракон, Хранитель Небес",
    "icon": "🐉",
    "level": 70,
    "hp": 50000,
    "attack_min": 300,
    "attack_max": 450,
    "defense": 250,
    "location": "dragon_lair",
    "location_name": "Логово Дракона",
    "available_duration": 3600,
    "description": "Древний дракон, парящий в небесах. Его крылья закрывают солнце.",
    "enemies": [
      {"name": "Драконий страж", "level": 60, "damage": "180-250", "icon": "🐉", "drops": "Драконья чешуя"},
      {"name": "Небесный дракончик", "level": 65, "damage": "200-280", "icon": "🪽", "drops": "Крыло дракона"}
    ],
    "rewards": {"exp": 3000, "gold": 8000, "points": 300},
    "drops": [
      {"item": "dragon_scale_ancient", "name": "Древняя чешуя", "chance": 15, "icon": "🛡️"},
      {"item": "dragon_heart_ancient", "name": "Сердце дракона", "chance": 8, "icon": "❤️"},
      {"item": "dragon_sword", "name": "Драконий меч", "chance": 5, "icon": "⚔️"}
    ],
    "rumor": "Говорят, дракон охраняет яйцо, из которого вылупится новый повелитель небес."
  },
  "demon_lord": {
    "name": "Повелитель Демонов, Князь Тьмы",
    "icon": "😈",
    "level": 80,
    "hp": 80000,
    "attack_min": 400,
    "attack_max": 600,
    "defense": 300,
    "location": "hell_gate",
    "location_name": "Врата Ада",
    "available_duration": 7200,
    "description": "Владыка преисподней, вырвавшийся из ада.",
    "enemies": [
      {"name": "Демон-воин", "level": 70, "damage": "250-350", "icon": "😈", "drops": "Демоническая кровь"},
      {"name": "Адский пес", "level": 75, "damage": "280-400", "icon": "🐕‍🦺", "drops": "Клык демона"}
    ],
    "rewards": {"exp": 5000, "gold": 15000, "points": 500},
    "drops": [
      {"item": "demon_heart", "name": "Сердце демона", "chance": 10, "icon": "❤️"},
      {"item": "demon_sword", "name": "Демонический меч", "chance": 6, "icon": "⚔️"},
      {"item": "demon_armor", "name": "Демоническая броня", "chance": 4, "icon": "🛡️"}
    ],
    "rumor": "Повелитель демонов ищет душу, чтобы разорвать оковы ада."
  },
  "archmage": {
    "name": "Архимаг, Хранитель Знаний",
    "icon": "🧙",
    "level": 90,
    "hp": 60000,
    "attack_min": 350,
    "attack_max": 500,
    "defense": 200,
    "location": "arcane_tower",
    "location_name": "Башня Арканума",
    "available_duration": 10800,
    "description": "Величайший маг всех времён, охраняющий древние знания.",
    "enemies": [
      {"name": "Магический страж", "level": 80, "damage": "280-400", "icon": "🔮", "drops": "Магический кристалл"},
      {"name": "Элементаль магии", "level": 85, "damage": "320-450", "icon": "✨", "drops": "Чистая мана"}
    ],
    "rewards": {"exp": 8000, "gold": 20000, "points": 800},
    "drops": [
      {"item": "archmage_staff", "name": "Посох архимага", "chance": 8, "icon": "🔮"},
      {"item": "spellbook", "name": "Книга заклинаний", "chance": 12, "icon": "📖"},
      {"item": "mana_crystal", "name": "Кристалл маны", "chance": 20, "icon": "💎"}
    ],
    "rumor": "Архимаг хранит секрет бессмертия в своей библиотеке."
  }
};

final Map<String, dynamic> bossesEvent = {
  "pumpkin_king": {
    "name": "Тыквоголовый",
    "icon": "🎃",
    "level": 30,
    "hp": 8000,
    "attack_min": 120,
    "attack_max": 180,
    "defense": 80,
    "location": "halloween_field",
    "location_name": "Тыквенное поле",
    "event_name": "halloween",
    "start_month": 10,
    "start_day": 25,
    "end_month": 10,
    "end_day": 31,
    "description": "Таинственное существо, появляющееся в канун Дня всех святых.",
    "enemies": [
      {"name": "Летучая мышь", "level": 20, "damage": "60-90", "icon": "🦇", "drops": "Крыло мыши"},
      {"name": "Призрачный слуга", "level": 25, "damage": "80-120", "icon": "👻", "drops": "Призрачная пыль"}
    ],
    "rewards": {"exp": 800, "gold": 2000, "points": 80},
    "drops": [
      {"item": "pumpkin_helmet", "name": "Тыквенный шлем", "chance": 15, "icon": "🎃"},
      {"item": "candy", "name": "Конфета", "chance": 100, "icon": "🍬"},
      {"item": "glowing_sword", "name": "Светящийся меч", "chance": 8, "icon": "⚔️"}
    ],
    "rumor": "Говорят, что тот, кто снимет шлем с Тыквоголового, получит его силу."
  },
  "ice_giant": {
    "name": "Ледяной великан",
    "icon": "❄️",
    "level": 40,
    "hp": 12000,
    "attack_min": 150,
    "attack_max": 220,
    "defense": 100,
    "location": "frozen_peak",
    "location_name": "Ледяная вершина",
    "event_name": "new_year",
    "start_month": 12,
    "start_day": 25,
    "end_month": 1,
    "end_day": 10,
    "description": "Гигантское существо из льда и снега, приносящее зимний холод.",
    "enemies": [
      {"name": "Снежный элементаль", "level": 30, "damage": "100-150", "icon": "❄️", "drops": "Снежный кристалл"},
      {"name": "Ледяной дракончик", "level": 35, "damage": "120-180", "icon": "🐉", "drops": "Ледяная чешуя"}
    ],
    "rewards": {"exp": 1000, "gold": 3000, "points": 100},
    "drops": [
      {"item": "snowflake", "name": "Снежинка", "chance": 100, "icon": "❄️"},
      {"item": "new_year_hat", "name": "Новогодний колпак", "chance": 20, "icon": "🎩"},
      {"item": "ice_staff", "name": "Ледяной посох", "chance": 10, "icon": "🔮"}
    ],
    "rumor": "Великан хранит секрет вечной зимы в своей ледяной короне."
  },
  "easter_bunny": {
    "name": "Пасхальный кролик",
    "icon": "🐰",
    "level": 25,
    "hp": 6000,
    "attack_min": 80,
    "attack_max": 120,
    "defense": 60,
    "location": "easter_meadow",
    "location_name": "Пасхальный луг",
    "event_name": "easter",
    "start_month": 3,
    "start_day": 20,
    "end_month": 4,
    "end_day": 15,
    "description": "Волшебный кролик, прячущий пасхальные яйца по всему миру.",
    "enemies": [
      {"name": "Золотой цыплёнок", "level": 20, "damage": "70-100", "icon": "🐥", "drops": "Золотое яйцо"},
      {"name": "Шоколадный заяц", "level": 22, "damage": "75-110", "icon": "🍫", "drops": "Шоколадное яйцо"}
    ],
    "rewards": {"exp": 600, "gold": 1500, "points": 60},
    "drops": [
      {"item": "easter_egg", "name": "Пасхальное яйцо", "chance": 100, "icon": "🥚"},
      {"item": "gift_basket", "name": "Корзина с подарками", "chance": 15, "icon": "🧺"},
      {"item": "carrot_sword", "name": "Морковный меч", "chance": 8, "icon": "🥕"}
    ],
    "rumor": "Кролик прячет самое большое золотое яйцо где-то в лесу."
  },
  "gingerbread_golem": {
    "name": "Имбирный голем",
    "icon": "🍪",
    "level": 35,
    "hp": 10000,
    "attack_min": 130,
    "attack_max": 190,
    "defense": 90,
    "location": "sweet_forest",
    "location_name": "Сладкий лес",
    "event_name": "birthday",
    "start_month": 6,
    "start_day": 1,
    "end_month": 6,
    "end_day": 7,
    "description": "Ожившая имбирная фигура, охраняющая праздничные подарки.",
    "enemies": [
      {"name": "Имбирный солдат", "level": 28, "damage": "90-130", "icon": "🍪", "drops": "Имбирное печенье"},
      {"name": "Конфетный дух", "level": 32, "damage": "110-160", "icon": "🍬", "drops": "Леденец"}
    ],
    "rewards": {"exp": 900, "gold": 2500, "points": 90},
    "drops": [
      {"item": "gift_box", "name": "Подарочная коробка", "chance": 100, "icon": "🎁"},
      {"item": "birthday_cake", "name": "Праздничный торт", "chance": 20, "icon": "🎂"},
      {"item": "confetti", "name": "Конфетти", "chance": 50, "icon": "🎉"}
    ],
    "rumor": "Голем спрятал главный подарок где-то внутри себя."
  }
};

final Map<String, dynamic> mapLocations = {
  "tower": {
    "name": "БАШНЯ МАГА",
    "icon": "🧙",
    "x": 0.30202944713932, "y": 0.18962541345048,
    "desc": "Высокая башня, где живёт могущественный маг.",
    "enemies": [
      {"name": "Магический страж", "level": 20, "damage": "70-100", "icon": "🗡️", "drops": "Магический свиток", "mob_id": "golem"},
      {"name": "Вызванный демон", "level": 25, "damage": "80-120", "icon": "😈", "drops": "Демонический артефакт", "mob_id": "demon"},
      {"name": "Безумный маг", "level": 22, "damage": "75-110", "icon": "🧙", "drops": "Магический свиток", "mob_id": "ghost"}
    ],
    "quests": ["Сердце демона", "Магический свиток"],
    "rumor": "На верхнем этаже хранится Книга Мертвых."
  },
  "forest": {
    "name": "ТЁМНЫЙ ЛЕС",
    "icon": "🌲",
    "x": 0.43908601963205, "y": 0.51293224177948,
    "desc": "Дремучий лес, где солнце едва пробивается сквозь кроны.",
    "enemies": [
      {"name": "Лесной волк", "level": 3, "damage": "20-35", "icon": "🐺", "drops": "Волчья шкура", "mob_id": "wolf"},
      {"name": "Дикий кабан", "level": 4, "damage": "25-40", "icon": "🐗", "drops": "Клык кабана", "mob_id": "orc"},
      {"name": "Лесной паук", "level": 5, "damage": "30-45", "icon": "🕷️", "drops": "Паутина", "mob_id": "rat"}
    ],
    "quests": ["Охота на волков", "Волчьи шкуры"],
    "rumor": "По ночам на поляне собираются ведьмы."
  },
  "city": {
    "name": "ГОРОД",
    "icon": "🏰",
    "x": 0.59858453269976, "y": 0.67961486398357,
    "desc": "Столица королевства Эвория.",
    "enemies": [
      {"name": "Крысолюд", "level": 1, "damage": "10-20", "icon": "🐀", "drops": "Крысиный хвост", "mob_id": "rat"},
      {"name": "Гоблин-разбойник", "level": 2, "damage": "15-30", "icon": "👤", "drops": "Монеты", "mob_id": "orc"},
      {"name": "Бродячий пёс", "level": 1, "damage": "8-15", "icon": "🐕", "drops": "Шкура", "mob_id": "wolf"}
    ],
    "quests": ["Крысиная угроза", "Трофеи Крысы"],
    "rumor": "Под городом есть древние катакомбы."
  },
  "volcano": {
    "name": "ОГНЕННАЯ ГОРА",
    "icon": "🔥",
    "x": 0.7476637087722, "y": 0.22267459190055,
    "desc": "Действующий вулкан, потоки лавы и пепла.",
    "enemies": [
      {"name": "Огненный саламандер", "level": 30, "damage": "100-150", "icon": "🦎", "drops": "Огненный самоцвет", "mob_id": "dragon"},
      {"name": "Лавовый голем", "level": 35, "damage": "120-180", "icon": "🗿", "drops": "Вулканическое стекло", "mob_id": "golem"},
      {"name": "Огненный дракончик", "level": 40, "damage": "150-200", "icon": "🐉", "drops": "Драконья чешуя", "mob_id": "dragon"}
    ],
    "quests": ["Чешуя дракона", "Охотник на драконов"],
    "rumor": "В сердце вулкана спит Великий Дракон."
  },
  "mountains": {
    "name": "ГОРНЫЙ ПЕРЕВАЛ",
    "icon": "🏔️",
    "x": 0.52244199890739, "y": 0.24422838916517,
    "desc": "Опасный перевал, холодный ветер, скользкие тропы.",
    "enemies": [
      {"name": "Горный тролль", "level": 10, "damage": "50-80", "icon": "👹", "drops": "Зуб тролля", "mob_id": "troll"},
      {"name": "Снежный барс", "level": 8, "damage": "40-60", "icon": "🐆", "drops": "Мех барса", "mob_id": "wolf"},
      {"name": "Каменный голем", "level": 12, "damage": "60-90", "icon": "🗿", "drops": "Кристаллы", "mob_id": "golem"}
    ],
    "quests": ["Охотник на троллей", "Зубы тролля"],
    "rumor": "На высокой горе есть древний храм."
  },
  "mansion": {
    "name": "ЗАБРОШЕННЫЙ ОСОБНЯК",
    "icon": "🏚️",
    "x": 0.28119042315427, "y": 0.44252319858499,
    "desc": "Старый особняк на холме.",
    "enemies": [
      {"name": "Призрак", "level": 15, "damage": "50-70", "icon": "👻", "drops": "Призрачная эссенция", "mob_id": "ghost"},
      {"name": "Летучая мышь", "level": 12, "damage": "40-60", "icon": "🦇", "drops": "Крыло", "mob_id": "rat"},
      {"name": "Призрачная крыса", "level": 10, "damage": "30-50", "icon": "🐀", "drops": "Старинная монета", "mob_id": "rat"}
    ],
    "quests": ["Призрачная угроза", "Призрачная эссенция"],
    "rumor": "В подвале спрятано проклятое зеркало."
  },
  "crypt": {
    "name": "СКЛЕП",
    "icon": "🕯️",
    "x": 0.74365615480149, "y": 0.86785125732422,
    "desc": "Древнее захоронение рыцарей и королей.",
    "enemies": [
      {"name": "Скелет", "level": 5, "damage": "25-40", "icon": "💀", "drops": "Кость", "mob_id": "skeleton"},
      {"name": "Зомби", "level": 7, "damage": "30-50", "icon": "🧟", "drops": "Гнилая плоть", "mob_id": "skeleton"},
      {"name": "Скелет-рыцарь", "level": 10, "damage": "45-65", "icon": "⚔️", "drops": "Древний свиток", "mob_id": "skeleton"}
    ],
    "quests": ["Истребление нежити", "Кости скелетов"],
    "rumor": "В глубине склепа похоронен великий король."
  },
  "ruins": {
    "name": "ДРЕВНИЕ РУИНЫ",
    "icon": "🏛️",
    "x": 0.74606061718501, "y": 0.47988306332941,
    "desc": "Останки древней цивилизации.",
    "enemies": [
      {"name": "Каменный голем", "level": 25, "damage": "80-120", "icon": "🗿", "drops": "Ядро голема", "mob_id": "golem"},
      {"name": "Магический конструкт", "level": 28, "damage": "90-130", "icon": "🤖", "drops": "Магический кристалл", "mob_id": "golem"},
      {"name": "Дух-хранитель", "level": 30, "damage": "100-140", "icon": "👻", "drops": "Древний артефакт", "mob_id": "ghost"}
    ],
    "quests": ["Ядро голема", "Древний артефакт"],
    "rumor": "Под руинами находится подземный храм."
  },
  "castle": {
    "name": "ЗАМОК",
    "icon": "👑",
    "x": 0.88231570221657, "y": 0.65806109284701,
    "desc": "Величественный замок королевской семьи.",
    "enemies": [
      {"name": "Королевский страж", "level": 15, "damage": "60-90", "icon": "🛡️", "drops": "Королевская монета", "mob_id": "orc"},
      {"name": "Теневой убийца", "level": 18, "damage": "65-95", "icon": "🗡️", "drops": "Магическое кольцо", "mob_id": "ghost"},
      {"name": "Придворный маг", "level": 20, "damage": "70-100", "icon": "🔮", "drops": "Драгоценность", "mob_id": "demon"}
    ],
    "quests": ["Сердце демона", "Защита замка"],
    "rumor": "В подземельях замка хранится чёрный дракон."
  }
};

const List<int> questKillCounts = [1, 2, 3, 5, 8, 10, 15, 20];
const List<int> questCollectCounts = [1, 2, 3, 5, 8, 10, 15, 20];

const List<String> playerStatOrder = [
  'strength',
  'agility',
  'intuition',
  'endurance',
  'intellect',
  'wisdom',
  'spirit',
];

const Map<String, String> playerStatNames = {
  'strength': 'Сила',
  'agility': 'Ловкость',
  'intuition': 'Интуиция',
  'endurance': 'Выносливость',
  'intellect': 'Интеллект',
  'wisdom': 'Мудрость',
  'spirit': 'Дух',
};

const Map<String, String> buffNames = {
  'exp': '⭐ к опыту',
  'max_hp': '❤️ к HP',
  'strength': '💪 к силе',
  'speed': '⚡ к скорости',
  'defense': '🛡️ к защите',
  'gold': '💰 к золоту',
  'attack': '⚔️ к атаке',
  'crit_chance': '🎯 к шансу крита',
  'evasion': '🌀 к уклонению',
  'regen': '💚 к регенерации',
  'berserk': '🐉 к атаке',
};

final List<(String, Map<String, dynamic>)> allRumors = [
  for (final e in strangerRumors.entries)
    (e.key, {...e.value as Map<String, dynamic>, 'seller': 'stranger'}),
  for (final e in guardRumors.entries)
    (e.key, {...e.value as Map<String, dynamic>, 'seller': 'guard'}),
  for (final e in adventurerRumors.entries)
    (e.key, {...e.value as Map<String, dynamic>, 'seller': 'adventurer'}),
];

String itemField(Map<String, dynamic>? item, String key,
    {Object? fallback = ''}) {
  if (item == null) return fallback is String ? fallback : '';
  final v = item[key];
  return v?.toString() ?? (fallback is String ? fallback : '');
}

int itemInt(Map<String, dynamic>? item, String key, [int fallback = 0]) {
  if (item == null) return fallback;
  return (item[key] as num?)?.toInt() ?? fallback;
}

String bonusesLine(Map<dynamic, dynamic> bonuses) {
  if (bonuses.isEmpty) return '';
  const names = {
    'attack': ' атака',
    'defense': ' защита',
    'crit_chance': '% крит',
    'hp_restore': ' HP',
    'evasion': '% уклон',
  };
  return bonuses.entries
      .map((e) => '+${e.value}${names[e.key] ?? ' ${e.key}'}')
      .join(', ');
}
