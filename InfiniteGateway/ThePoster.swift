//
//  ThePoster.swift
//  DIMP
//
//  Created by Eric Betts on 6/26/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

//ThePoster is a way of looking up token data.
//It helps associate internal represetations from the token 
//data to the real world name and characteristics.
//Like how you might use a real world poster to look 
//at a list of the figures, their pictures, or stats

class Model : NSObject {
    let DECIMAL = 10
    var id : Int
    enum Shape : Int {
        case None = 0
        case Figure = 1
        case PlaySet = 2
        case RoundPowerDisk = 3
        case HexPowerDisk = 4
        func desc() -> String {
            switch self.rawValue {
            case 1:
                return "Figure"
            case 2:
                return "Play Sets / Toy Box"
            case 3:
                return "Round Power Disc"
            case 4:
                return "Hexagonal Power Disc"
            default:
                return "Unknown"
            }
        }
    }
    var shape : Shape {
        get {
            let shapeVal = id / 1000000 % DECIMAL
            return Shape(rawValue: shapeVal)!
        }
    }
    var generation : UInt8 {
        get {
            return UInt8(id / 100 % 10) + 1
        }
    }
    var name : String {
        return ThePoster.getName(id)
    }
    
    override var description: String {
        get {
            return "DI \(generation).0 \(name)"
        }
    }
    
    init(id: Int) {
        self.id = id
    }
    
    func copyWithZone(zone: NSZone) -> Model {
        return Model(id: self.id)
    }
    
}

class ThePoster {
    static var models : [Model] = {
        return names.keys.map{return Model(id: $0)}.sort({ $0.description < $1.description })
    }()
    
    static func getName(id: Int) -> String {
        return names.get(id, defaultValue: "<\(id)>")
    }

    //http://disneyinfinity.wikia.com/wiki/Disney_Infinity/Model_Numbers
    //http://www.disneyinfinityfans.com/viewtopic.php?f=9&t=2269&start=63
    //Look into more complex structure containing name, generation (or get from token data), type (disk, playset, etc)
    static let names : [Int:String] = [
        1000001 : "Mr. Incredible",
        1000002 : "Sulley",
        1000003 : "Captain Jack Sparrow",
        1000004 : "Lone Ranger",
        1000005 : "Tonto",
        1000006 : "Lightning McQueen",
        1000007 : "Holley Shiftwell",
        1000008 : "Buzz Lightyear",
        1000009 : "Jessie",
        1000010 : "Mike Wazowski",
        1000011 : "Mrs. Incredible",
        1000012 : "Hector Barbossa",
        1000013 : "Davy Jones",
        1000014 : "Randy",
        1000015 : "Syndrome",
        1000016 : "Woody",
        1000017 : "Mater",
        1000018 : "Dash",
        1000019 : "Violet",
        1000020 : "Francesco Bernoulli",
        1000021 : "Sorcerer's Apprentice Mickey",
        1000022 : "Jack Skellington",
        1000023 : "Rapunzel",
        1000024 : "Anna",
        1000025 : "Elsa",
        1000026 : "Phineas",
        1000027 : "Agent P",
        1000028 : "Wreck-It Ralph",
        1000029 : "Vanellope",
        1000030 : "Mr. Incredible (Crystal)",
        1000031 : "Captain Jack Sparrow (Crystal)",
        1000032 : "Sulley (Crystal)",
        1000033 : "Lightning McQueen (Crystal)",
        1000034 : "Lone Ranger (Crystal)",
        1000035 : "Buzz Lightyear (Crystal)",
        1000036 : "Agent P (Crystal)",
        1000037 : "Sorcerer's Apprentice Mickey (Crystal)",
        1000100 : "Captain America",
        1000101 : "Hulk",
        1000102 : "Iron Man",
        1000103 : "Thor",
        1000104 : "Groot",
        1000105 : "Rocket Raccoon",
        1000106 : "Star-Lord",
        1000107 : "Spider-Man",
        1000108 : "Nick Fury",
        1000109 : "Black Widow",
        1000110 : "Hawkeye",
        1000111 : "Drax",
        1000112 : "Gamora",
        1000113 : "Iron Fist",
        1000114 : "Nova",
        1000115 : "Venom",
        1000116 : "Donald Duck",
        1000117 : "Aladdin",
        1000118 : "Stitch",
        1000119 : "Merida",
        1000120 : "Tinker Bell",
        1000121 : "Maleficent",
        1000122 : "Hiro",
        1000123 : "Baymax",
        1000124 : "Green Goblin",
        1000125 : "Ronan",
        1000126 : "Loki",
        1000127 : "Falcon",
        1000128 : "Yondu",
        1000129 : "Jasmine",
        1000134 : "Black Suit Spider-Man",
        1000150 : "Sam Flynn",
        1000151 : "Quorra",
        1000152 : "Clu",
        1000200 : "Anakin Skywalker",
        1000201 : "Obi-Wan Kenobi",
        1000202 : "Yoda",
        1000203 : "Ahsoka Tano",
        1000204 : "Darth Maul",
        1000206 : "Luke Skywalker",
        1000207 : "Han Solo",
        1000208 : "Princess Leia",
        1000209 : "Chewbacca",
        1000210 : "Darth Vader",
        1000211 : "Boba Fett",
        1000212 : "Ezra Bridger",
        1000213 : "Kanan Jarrus",
        1000214 : "Sabine Wren",
        1000215 : "Zeb Orrelios",
        1000216 : "Joy",
        1000217 : "Anger",
        1000218 : "Fear",
        1000219 : "Sadness",
        1000220 : "Disgust",
        1000221 : "Mickey Mouse",
        1000222 : "Minnie Mouse",
        1000223 : "Mulan",
        1000224 : "Olaf",
        1000226 : "Ultron",
        1000230 : "Finn",
        1000231 : "Kylo Ren",
        1000232 : "Poe Dameron",
        1000233 : "Rey",
        1000235 : "Spot",
        1000236 : "Nick Wilde",
        1000237 : "Judy Hopps",
        1000238 : "Hulkbuster",
        1000239 : "Anakin Skywalker Light FX",
        1000240 : "Obi-Wan Kenobi Light FX",
        1000241 : "Yoda Light FX",
        1000242 : "Luke Skywalker Light FX",
        1000243 : "Darth Vader Light FX",
        1000244 : "Kanan Jarrus Light FX",
        1000245 : "Kylo Ren Light FX",
        //MARK- Hex playsets
        2000001 : "Starter Pack Playsets",
        2000002 : "The Lone Ranger Play Set",
        2000003 : "Cars Play Set",
        2000004 : "Toy Story in Space Play Set",
        2000100 : "Marvel's The Avengers Play Set",
        2000101 : "Marvel's Spider-Man Play Set",
        2000102 : "Marvel's Guardians of the Galaxy Play Set",
        2000103 : "Assault on Asgard",
        2000104 : "Escape from Kyln",
        2000105 : "Stitch's Tropical Rescue",
        2000106 : "Brave Forest Siege",
        2000200 : "Inside Out Playset",
        2000202 : "Star Wars: Twilight of the Republic Play Set",
        2000203 : "Star Wars: Rise Against the Empire Play Set",
        2000204 : "Star Wars: The Force Awakens Play Set",
        2000205 : "Marvel Battlegrounds",
        2000206 : "Toy Box Speedways",
        2000207 : "Toy Box Takeover",
        2000208 : "SW: The Force Awakens play set 2",
        //MARK- Round powerdisks
        3000003 : "Bolt's Super Strength",
        3000004 : "Ralph's Power of Destruction",
        3000005 : "Chernabog's Power",
        3000006 : "C.H.R.O.M.E. Damage Increaser (Rare)",
        3000007 : "Dr. Doofenshmirtz's Damage-Inator!",
        3000008 : "Electro-Charge",
        3000009 : "Fix-It Felix's Repair Power",
        3000010 : "Rapunzel's Healing",
        3000011 : "C.H.R.O.M.E. Armor Shield",
        3000012 : "Star Command Shield",
        3000013 : "Violet's Force Field",
        3000014 : "Pieces of Eight",
        3000015 : "Scrooge McDuck's Lucky Dime (Rare)",
        3000016 : "User Control (Rare)",
        3000017 : "Sorcerer Mickey's Hat",
        3000062 : "Emperor Zurg's Wrath (Rare)",
        3000063 : "Merlin's Summon (Rare)",
        3000165 : "Enchanted Rose",
        3000166 : "Mulan's Training Uniform",
        3000167 : "Flubber",
        3000168 : "S.H.I.E.L.D. Helicarrier Strike",
        3000169 : "Zeus' Thunderbolts",
        3000170 : "King Louie's Monkeys",
        3000171 : "Infinity Gauntlet (Rare)",
        3000173 : "Sorcerer Supreme",
        3000174 : "Maleficent's Spell Cast",
        3000175 : "Chernabog's Spirit Cyclone",
        3000176 : "Marvel Team-Up: Capt. Marvel",
        3000177 : "Marvel Team-Up: Iron Patriot",
        3000178 : "Marvel Team-Up: Ant-Man",
        3000179 : "Marvel Team-Up: White Tiger",
        3000180 : "Marvel Team-Up: Yondu (Rare)",
        3000181 : "Marvel Team-Up: Winter Soldier",
        3000182 : "Stark Arc Reactor",
        3000183 : "Gamma Rays",
        3000184 : "Alien Symbiote",
        3000185 : "All for One",
        3000186 : "Sandy Claws' Surprise",
        3000187 : "Glory Days",
        3000188 : "Cursed Pirate Gold",
        3000189 : "Sentinel of Liberty",
        3000190 : "The Immortal Iron Fist",
        3000191 : "Space Armor",
        3000192 : "Rags to Riches",
        3000193 : "Ultimate Falcon",
        3000200 : "Tomorrowland Time Bomb",
        3000206 : "Galactic Team-Up: Mace Windu",
        3000231 : "Kingdom Hearts Mickey",
        //MARK- Hex powerdisks
        4000018 : "Mickey's Car",
        4000019 : "Cinderella's Coach",
        4000020 : "Electric Mayhem Bus",
        4000021 : "Cruella De Vil's Car",
        4000022 : "Pizza Planet Delivery Truck",
        4000023 : "Mike's New Car (Rare)",
        4000025 : "Parking Lot Tram",
        4000026 : "Jolly Roger (Rare)",
        4000027 : "Dumbo (Rare)",
        4000028 : "Calico's Helicopter",
        4000029 : "Maximus",
        4000030 : "Agnus",
        4000031 : "Abu the Elephant (Rare)",
        4000032 : "Headless Horseman's Horse",
        4000033 : "Phillipe",
        4000034 : "Khan",
        4000035 : "Tantor",
        4000036 : "Dragon Firework Cannon",
        4000037 : "Stitch's Blaster",
        4000038 : "Toy Story Mania Blaster",
        4000039 : "Flamingo Croquet Mallet",
        4000040 : "Carl Fredricksen's Cane",
        4000041 : "Hangin' Ten Stitch With Surfboard",
        4000042 : "Condorman Glider (Rare)",
        4000043 : "WALL-E's Fire Extinguisher (Rare)",
        4000044 : "On the Grid (Rare)",
        4000045 : "WALL-E's Collection",
        4000046 : "King Candy's Dessert Toppings",
        4000048 : "Victor's Experiments",
        4000049 : "Jack's Scary Decorations",
        4000051 : "Frozen Flourish",
        4000052 : "Rapunzel's Kingdom",
        4000053 : "TRON Interface (Rare)",
        4000054 : "Buy N Large Atmosphere",
        4000055 : "Sugar Rush Sky",
        4000057 : "New Holland Skyline",
        4000058 : "Halloween Town Sky",
        4000060 : "Chill in the Air",
        4000061 : "Rapunzel's Birthday Sky",
        4000064 : "Astro Blasters Space Cruiser (Rare)",
        4000065 : "Marlin's Reef",
        4000066 : "Nemo's Seascape",
        4000067 : "Alice's Wonderland",
        4000068 : "Tulgey Wood",
        4000069 : "Tri-State Area Terrain",
        4000070 : "Danville Sky",
        4000101 : "Stark Tech",
        4000102 : "Spider-Streets",
        4000103 : "World War Hulk",
        4000104 : "Gravity Falls Forest",
        4000105 : "Neverland",
        4000106 : "Simba's Pridelands",
        4000108 : "Calhoun's Command",
        4000109 : "Star-Lord's Galaxy",
        4000110 : "Dinosaur World",
        4000111 : "Groot's Roots",
        4000112 : "Mulan's Countryside",
        4000113 : "The Sands of Agrabah",
        4000116 : "A Small World",
        4000117 : "View from the Suit",
        4000118 : "Spider-Sky",
        4000119 : "World War Hulk Sky",
        4000120 : "Gravity Falls Sky",
        4000121 : "Second Star to the Right",
        4000122 : "The King's Domain",
        4000124 : "CyBug Swarm",
        4000125 : "The Rip",
        4000126 : "Forgotten Skies",
        4000127 : "Groot's View",
        4000128 : "The Middle Kingdom",
        4000132 : "Skies of the World",
        4000133 : "S.H.I.E.L.D. Containment Truck",
        4000134 : "Main Street Electrical Parade Float",
        4000135 : "Mr. Toad's Motorcar",
        4000136 : "Le Maximum",
        4000137 : "Alice in Wonderland's Caterpillar",
        4000138 : "Eglantine's Motorcycle",
        4000139 : "Medusa's Swamp Mobile",
        4000140 : "Hydra Motorcycle",
        4000141 : "Darkwing Duck's Ratcatcher",
        4000143 : "The USS Swinetrek",
        4000145 : "Spider-Copter",
        4000146 : "Aerial Area Rug",
        4000147 : "Jack-O-Lantern's Glider",
        4000148 : "Spider-Buggy",
        4000149 : "Jack Skellington's Reindeer",
        4000150 : "Fantasyland Carousel Horse",
        4000151 : "Odin's Horse",
        4000152 : "Gus the Mule",
        4000154 : "Darkwing Duck's Grappling Gun",
        4000156 : "Ghost Rider's Chain Whip",
        4000157 : "Lew Zealand's Boomerang Fish",
        4000158 : "Sergeant Calhoun's Blaster",
        4000160 : "Falcon's Wings",
        4000161 : "Mabel's Kittens for Fists",
        4000162 : "Jim Hawkins' Solar Board",
        4000163 : "Black Panther's Vibranium Knives",
        4000164 : "Cloak of Levitation",
        4000165 : "Aladdin's Magic Carpet",
        4000166 : "Honey Lemon's Ice Capsules",
        4000167 : "Jasmine's Palace View",
        4000193 : "Lola",
        4000194 : "Spider-Cycle (Rare)",
        4000195 : "The Avenjet",
        4000196 : "Spider-Glider",
        4000201 : "Retro Gun",
        4000202 : "Tomorrowland Futurescape",
        4000203 : "Tomorrowland Stratosphere",
        4000204 : "Skies over Felucia",
        4000205 : "Forest of Felucia",
        4000207 : "General Grievous' Wheel Bike",
        4000210 : "Star Wars Slave 1",
        4000211 : "Star Wars Y-Wing",
        4000212 : "Arlo",
        4000213 : "Nash",
        4000214 : "Butch",
        4000215 : "Ramsey",
    ]
}
