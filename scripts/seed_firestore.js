/**
 * seed_firestore.js
 *
 * One-time script to load the AquaNook catalogue (sellers + products) into
 * Firestore. Run this ONCE after your Firestore database is created.
 *
 * Setup:
 *   1. In Firebase Console: Project settings > Service accounts >
 *      "Generate new private key" — save the downloaded file as
 *      serviceAccountKey.json in this same folder (scripts/).
 *   2. npm install firebase-admin   (run this inside the scripts/ folder,
 *      or add firebase-admin as a devDependency at the project root)
 *   3. Run from the PROJECT ROOT (so the assets/images/ paths resolve):
 *        node scripts/seed_firestore.js
 *
 * This script is safe to re-run — it overwrites products/sellers with the
 * same ids rather than duplicating them.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ---------------------------------------------------------------------
// Catalogue data — identical to what the old server.js generated.
// ---------------------------------------------------------------------
const SELLERS = [
  { id: 1, name: "Aqua Paradise Co.", avatar: "🐠", tagline: "Fresh fish and friendly advice since day one." },
  { id: 2, name: "Fin & Fauna", avatar: "🐡", tagline: "Curated fish and plants for calm, healthy tanks." },
  { id: 3, name: "The Coral Nook", avatar: "🪸", tagline: "Decor and hardscape pieces with personality." },
  { id: 4, name: "Blue Lagoon Aquatics", avatar: "🌊", tagline: "Everything you need for a thriving aquascape." },
  { id: 5, name: "Nano Reef Supply", avatar: "🐚", tagline: "Small-tank specialists — nano and desktop setups." },
  { id: 6, name: "Betta & Beyond", avatar: "🐟", tagline: "Betta experts with a soft spot for rare colors." },
  { id: 7, name: "Tankside Traders", avatar: "🧰", tagline: "Reliable gear and equipment for every tank size." },
  { id: 8, name: "Wet Pets Co.", avatar: "🫧", tagline: "Your neighborhood aquarium supply shop." }
];

// ข้อมูลจำลอง สินค้าปลาและอุปกรณ์ตู้ปลา
let PRODUCTS = [
  { id: 1, name: "Fancy Goldfish", category: "fish", price: 9.99, rating: 4.5, stock: 14, imageUrl: "assets/images/fish/fancy-goldfish-on-gravel.jpg", blurb: "A plump, round classic goldfish in varieties like Oranda and Ryukin — hardy, sociable, and known to recognize its keeper over time.", sellerId: 1 },
  { id: 2, name: "Blue Guppy Pair", category: "fish", price: 7.49, rating: 4.7, stock: 22, imageUrl: "assets/images/fish/Blue guppy pair.jpg", blurb: "A pair of guppies in deep metallic blue with broad, flowing tails — easy to keep and quick to breed, perfect for beginners.", sellerId: 2 },
  { id: 3, name: "Crown Tail Betta", category: "fish", price: 18.99, rating: 4.9, stock: 9, imageUrl: "assets/images/fish/crowntail.jpg", blurb: "Known for its spiky, crown-like tail and bold colors — a striking solo centerpiece best kept alone in a small tank.", isNew: true, sellerId: 3 },
  { id: 4, name: "Neon Tetra (School of 6)", category: "fish", price: 16.99, rating: 4.3, stock: 30, imageUrl: "assets/images/fish/school_of_green_neon_tetras.jpg", blurb: "A shimmering green-blue stripe runs the length of each fish — schools beautifully together and looks stunning in a planted tank.", sellerId: 4 },
  { id: 5, name: "Driftwood Branch", category: "decor", price: 14.99, rating: 4.6, stock: 17, imageUrl: "assets/images/decoration/Driftwood Branch.jpg", blurb: "Real driftwood with natural branching — forms the tank's hardscape and releases mild tannins that mimic a wild blackwater stream.", sellerId: 5 },
  { id: 6, name: "Sunken Castle Ornament", category: "decor", price: 12.49, rating: 4.2, stock: 12, imageUrl: "assets/images/decoration/Sunken Castle Ornament.jpg", blurb: "A weathered resin ruin with archways for fish to swim through — adds a touch of fantasy to the tank.", sellerId: 6 },
  { id: 7, name: "Whisper Air Pump", category: "equipment", price: 13.99, rating: 4.8, stock: 20, imageUrl: "assets/images/gear/Whisper air pump.jpg", blurb: "Built for near-silent operation with steady airflow — boosts oxygen levels without disturbing the room.", sellerId: 7 },
  { id: 8, name: "Compact Aquarium Filter", category: "equipment", price: 27.99, rating: 5.0, stock: 10, imageUrl: "assets/images/gear/Mini-Hang-On-Aquarium-Filter.jpg", blurb: "A compact hang-on-back filter that saves inside space, installs easily, and runs quietly — great for small tanks and betta bowls.", isNew: true, sellerId: 8 }
];

// Realistic price/rating/blurb for every image that isn't hand-written into
// PRODUCTS above. Keyed by the exact imageUrl the loop below builds.
// Anything NOT in this map (e.g. a new image dropped in later) still falls
// back to a placeholder $5.99 / 4.6 / generic blurb so the app never
// crashes on missing data.
const EXTRA_PRICING = {
  // ---- fish ----
  "assets/images/fish/Angelfish-Blue-Zebra.jpg": { price: 12.99, rating: 4.6, blurb: "Tall, elegant fins and a graceful, unhurried glide — a striking centerpiece for a medium-to-tall planted tank." },
  "assets/images/fish/Blue Gourami.jpg": { price: 8.99, rating: 4.4, blurb: "Pale blue with distinctive dark spots, tough and adaptable — a forgiving choice for new fishkeepers." },
  "assets/images/fish/Bolivian-Ram.jpg": { price: 9.99, rating: 4.5, blurb: "A gentle dwarf cichlid with soft, subtle coloring — peaceful enough to share a community tank." },
  "assets/images/fish/Cardinal_Paracheirodon.jpg": { price: 3.49, rating: 4.7, blurb: "A glowing blue stripe over a vivid red band running nose to tail — even more vibrant than a neon tetra in a big school." },
  "assets/images/fish/Cherry-Barb-Rohanella-titteya.jpg": { price: 3.99, rating: 4.4, blurb: "Males flush cherry-red when courting — a peaceful, easygoing splash of color against green plants." },
  "assets/images/fish/Corydoras Catfish.jpg": { price: 4.99, rating: 4.8, blurb: "A friendly bottom-dweller that noses through the substrate for leftovers — the tank's tireless little cleanup crew." },
  "assets/images/fish/Diamond-Tetra.jpg": { price: 4.49, rating: 4.3, blurb: "Scales catch the light like scattered diamonds, glittering more and more as the fish matures." },
  "assets/images/fish/Discus.jpg": { price: 34.99, rating: 4.9, blurb: "Round, flat, and regal — the 'king of the aquarium' rewards clean, stable water with jaw-dropping color." },
  "assets/images/fish/Dwarf Gourami.jpg": { price: 6.99, rating: 4.2, blurb: "Bold orange-and-blue stripes with a pair of feeler-like fins — hardy, tame, and full of personality." },
  "assets/images/fish/Dwarf-puffer-fish.jpg": { price: 7.99, rating: 4.5, blurb: "Thumbnail-sized with big, independently-swiveling eyes — an endearing little hunter that helps keep snail numbers down." },
  "assets/images/fish/Endler's Livebearer.jpg": { price: 4.99, rating: 4.6, blurb: "A pocket-sized livebearer with natural iridescent patterning, males especially bright — perfect for nano tanks." },
  "assets/images/fish/Goldfish.jpg": { price: 2.99, rating: 4.0, blurb: "A classic, sociable goldfish — hardy and easy to care for, a favorite starter fish for any home tank." },
  "assets/images/fish/Harlequin Rasbora.jpg": { price: 3.99, rating: 4.5, blurb: "A bold black triangle marks the back half of each fish — schools in neat, orderly formation." },
  "assets/images/fish/Hatchetfish.jpg": { price: 5.49, rating: 4.1, blurb: "Flat-bellied and built for the surface — hatchetfish can leap, so keep the lid on, and fill out the tank's top layer." },
  "assets/images/fish/Molly.jpg": { price: 4.49, rating: 4.4, blurb: "Tough and easygoing, available in colors like solid black — also helps graze algae off surfaces." },
  "assets/images/fish/Otocinclus.jpg": { price: 4.99, rating: 4.7, blurb: "A tiny, gentle glass-cleaner that grazes algae off leaves and glass without bothering anyone." },
  "assets/images/fish/Penguin Tetra.jpg": { price: 3.99, rating: 4.3, blurb: "A bold black stripe runs into the lower tail, and it swims with a distinctive, slightly upward tilt." },
  "assets/images/fish/Threadfin Rainbowfish.jpg": { price: 6.99, rating: 4.6, blurb: "Long, trailing dorsal and anal fins that males flare dramatically to court females." },
  "assets/images/fish/Tigerbarb.jpg": { price: 3.99, rating: 4.0, blurb: "Bold black stripes over an orange-yellow body — active, fast, and always on the move in a group." },
  "assets/images/fish/german-blue-ram-fish.jpg": { price: 11.99, rating: 4.8, blurb: "Iridescent blue-and-gold scales with a splash of red at the eye — a dwarf cichlid built for a well-planted tank." },

  // ---- decor ----
  "assets/images/decoration/Anubias.jpg": { price: 8.99, rating: 4.8, blurb: "Thick, dark-green leaves that are famously tough — no bright light or CO2 needed, just tie it to wood or stone." },
  "assets/images/decoration/Aqua Soil.jpg": { price: 16.99, rating: 4.6, blurb: "Nutrient-rich substrate that gently lowers pH into the soft, slightly acidic range most planted-tank fish prefer." },
  "assets/images/decoration/Aquarium Background Poster.jpg": { price: 7.99, rating: 4.2, blurb: "A backdrop that hides cords and equipment behind the tank, making fish and plants pop in front of it." },
  "assets/images/decoration/Aquarium Sand.jpeg": { price: 12.99, rating: 4.5, blurb: "Fine, pre-washed sand for a clean, classic look — ideal for bottom-dwellers that like to dig." },
  "assets/images/decoration/Blue Artificial Coral.jpg": { price: 9.99, rating: 4.1, blurb: "A resin coral replica that brings reef color to the tank without touching a real reef." },
  "assets/images/decoration/Clay Shelter Tube.jpg": { price: 6.99, rating: 4.4, blurb: "A natural terracotta hideout and breeding spot for dwarf shrimp, dwarf cichlids, and other small fish." },
  "assets/images/decoration/Dragon Stone.jpg": { price: 14.99, rating: 4.7, blurb: "Rugged, scale-textured rock riddled with tiny pockets perfect for tying on moss or Anubias, without affecting pH." },
  "assets/images/decoration/Glass Pebbles.jpg": { price: 8.49, rating: 4.3, blurb: "Clear glass beads that catch the light and add sparkle to the substrate, in a range of colors." },
  "assets/images/decoration/Glow Stones.jpg": { price: 10.99, rating: 4.0, blurb: "Stones that soak up daylight and glow softly after the lights go out, for a magical after-dark tank." },
  "assets/images/decoration/Java Fern.jpg": { price: 7.49, rating: 4.9, blurb: "Wavy, easy-care fronds that thrive in moderate light — just tie the rhizome to wood or rock, no planting needed." },
  "assets/images/decoration/Lava Rock.jpg": { price: 9.49, rating: 4.5, blurb: "Lightweight, porous volcanic rock that doubles as a home base for the beneficial bacteria that break down waste." },
  "assets/images/decoration/Marimo Moss Ball.jpg": { price: 5.99, rating: 4.9, blurb: "A round, low-maintenance ball of natural moss that soaks up nitrates and adds a touch of charm." },
  "assets/images/decoration/Mini Clay Pot.jpg": { price: 4.99, rating: 4.2, blurb: "A small terracotta pot for potting plants or giving small fish a place to duck into." },
  "assets/images/decoration/Miniature Wooden Bridge.jpg": { price: 8.99, rating: 4.3, blurb: "A Japanese-garden-style bridge ornament that lends the layout a calm, curated feel." },
  "assets/images/decoration/Pink Silicone Aquarium Plants.jpg": { price: 6.49, rating: 4.0, blurb: "Soft silicone leaves that sway naturally with the current and won't snag delicate fins — safe for long-finned bettas." },
  "assets/images/decoration/Sea Shells.jpg": { price: 5.49, rating: 4.1, blurb: "Cleaned natural shells suited to marine tanks or hard-water cichlid setups." },
  "assets/images/decoration/Seiryu Stone.jpg": { price: 17.99, rating: 4.6, blurb: "Dark grey stone streaked with white mineral veins — the classic choice for Iwagumi-style aquascapes." },
  "assets/images/decoration/Slate Stone.jpg": { price: 11.99, rating: 4.4, blurb: "Flat, stackable natural stone for building caves, ledges, and shelves for fish to explore." },
  "assets/images/decoration/Sunken Ship Resin.jpg": { price: 15.99, rating: 4.7, blurb: "A shipwreck-themed ornament with hollow spaces fish can swim straight through — decor and hideout in one." },
  "assets/images/decoration/wasserpest-aquarium.jpg": { price: 4.99, rating: 4.5, blurb: "A fast-growing water plant that soaks up excess nutrients, shelters fry, and helps oxygenate the water." },

  // ---- fish food ----
  "assets/images/fish food/Atman.jpg": { price: 6.99, rating: 4.2, blurb: "An affordable, everyday flake food that covers the basics without stretching the budget." },
  "assets/images/fish food/CP_fish-food.jpg": { price: 5.49, rating: 4.0, blurb: "A trusted Thai brand formulated for local conditions, with the protein goldfish and koi need to grow well." },
  "assets/images/fish food/Deep_fish-food.jpg": { price: 7.99, rating: 4.3, blurb: "A concentrated formula built specifically for show goldfish — supports structure, color, and healthy digestion." },
  "assets/images/fish food/Hikari_fish-food.jpg": { price: 9.99, rating: 4.8, blurb: "Japan's benchmark fish food brand, researched and formulated by species — supports fast growth, bright color, and strong health." },
  "assets/images/fish food/JBL_fish-food.jpg": { price: 8.49, rating: 4.5, blurb: "A premium German formula made from quality-graded ingredients, so fish absorb more and waste less — keeping water clearer for longer." },
  "assets/images/fish food/Ocean Free_fish-food.jpg": { price: 6.49, rating: 4.1, blurb: "Specialty formulas for color enhancement and body or head growth, plus disease-prevention blends." },
  "assets/images/fish food/Sakura_fish-food.jpeg": { price: 5.99, rating: 4.2, blurb: "A long-time favorite in Thailand — its tri-color pellets float well and won't cloud the water, great for goldfish." },
  "assets/images/fish food/Sera_fish-food.png": { price: 10.99, rating: 4.7, blurb: "A premium German formula built from natural ingredients with no artificial additives, gentle on digestion and immunity." },
  "assets/images/fish food/Tetra_fish-food.jpg": { price: 7.49, rating: 4.6, blurb: "A globally trusted flake and small-pellet food that's easy to digest and gentle on water quality — ideal for small community fish." },
  "assets/images/fish food/Tropical_fish-food.jpg": { price: 8.99, rating: 4.4, blurb: "A specialty European range with high-spirulina and carnivore-focused formulas among its detailed lineup." },

  // ---- gear ----
  "assets/images/gear/Aquarium Cooling Fan.jpg": { price: 13.99, rating: 4.3, blurb: "A tiny clip-on fan that can drop water temperature by a couple of degrees — handy for planted tanks and shrimp in hot weather." },
  "assets/images/gear/Aquarium Heater.jpg": { price: 15.99, rating: 4.6, blurb: "Keeps water at a steady temperature, protecting fish from cold snaps during winter or in air-conditioned rooms." },
  "assets/images/gear/Aquarium Thermometer.jpg": { price: 3.99, rating: 4.4, blurb: "An accurate, easy-to-read thermometer for keeping a constant eye on water temperature." },
  "assets/images/gear/Automatic Fish Feeder.jpg": { price: 19.99, rating: 4.5, blurb: "Schedules precise feeding times and portions — one less worry when you're away from home." },
  "assets/images/gear/Breeding Box.jpg": { price: 9.99, rating: 4.2, blurb: "A clear acrylic divider for isolating sick fish, fry, or a mother about to give birth, safely inside the main tank." },
  "assets/images/gear/CO2 System.jpg": { price: 39.99, rating: 4.6, blurb: "A complete CO2 dosing setup that fuels lush plant growth and visible photosynthesis." },
  "assets/images/gear/Canister Filter.jpg": { price: 54.99, rating: 4.8, blurb: "High-capacity external filtration with room for plenty of media — built for medium-to-large, heavily stocked tanks." },
  "assets/images/gear/Fish Net.jpg": { price: 3.49, rating: 4.3, blurb: "A soft-mesh net that's gentle on scales and fins when moving fish or skimming debris." },
  "assets/images/gear/Gravel Vacuum.jpg": { price: 11.99, rating: 4.7, blurb: "Siphons leftover food and waste out of the substrate — a must for weekly water changes." },
  "assets/images/gear/LED Aquarium Light.jpg": { price: 24.99, rating: 4.7, blurb: "Energy-efficient lighting tuned to bring out fish colors and power healthy plant growth." },
  "assets/images/gear/Magnetic Glass Cleaner.jpg": { price: 12.99, rating: 4.5, blurb: "A magnetic glass scrubber that wipes algae off the inside of the glass without ever getting your hands wet." },
  "assets/images/gear/Sponge Filter.jpg": { price: 6.99, rating: 4.4, blurb: "Air-pump-driven filtration with a soft sponge that's completely fry-safe — ideal for breeding and shrimp tanks." },
  "assets/images/gear/Submersible Water Pump.jpg": { price: 14.99, rating: 4.3, blurb: "A compact underwater pump for circulation, waterfalls, or feeding into other filtration setups." },
  "assets/images/gear/Surface Skimmer.jpg": { price: 10.99, rating: 4.1, blurb: "Skims the oily film and debris off the water's surface, improving oxygen exchange and clarity." },
  "assets/images/gear/Timer Switch.jpg": { price: 8.99, rating: 4.0, blurb: "An automatic outlet timer for lights and CO2, keeping a consistent day-night rhythm for the tank." },
  "assets/images/gear/Top Filter Box.jpg": { price: 17.99, rating: 4.4, blurb: "An easy-to-maintain filter box that sits on the rim of the tank with generous room for filter media." },
  "assets/images/gear/UV Sterilizer.jpg": { price: 29.99, rating: 4.6, blurb: "Clears up green water and helps knock back waterborne bacteria for cleaner, healthier water." },
  "assets/images/gear/Undergravel Filter.jpg": { price: 9.99, rating: 4.0, blurb: "A filter plate hidden beneath the substrate that turns the gravel bed itself into a natural filter." },
  "assets/images/gear/Water Test Kit.jpg": { price: 8.49, rating: 4.8, blurb: "Testing solutions for pH, ammonia, nitrite, and nitrate — the easiest way to keep water safely in range." },
  "assets/images/gear/Wave Maker.jpg": { price: 16.99, rating: 4.5, blurb: "Generates natural-feeling current so fish can swim against the flow — especially suited to marine and river-species tanks." }
};

// Names (post name-derivation, i.e. dashes/underscores already turned into
// spaces) that should show the "NEW" badge in the app.
const NEW_PRODUCT_NAMES = new Set([
  'Discus',
  'Angelfish Blue Zebra',
  'Dragon Stone',
  'LED Aquarium Light',
  'CO2 System',
  'UV Sterilizer',
  'Hikari fish food',
  'Canister Filter',
  'Automatic Fish Feeder',
  'Marimo Moss Ball'
]);

// Include any catalog image that does not have a hand-written entry above.
const assetFolders = [
  { directory: 'fish', category: 'fish' },
  { directory: 'decoration', category: 'decor' },
  { directory: 'fish food', category: 'fish_food' },
  { directory: 'gear', category: 'equipment' }
];
let nextProductId = PRODUCTS.length + 1;
for (const folder of assetFolders) {
  const directoryPath = path.join(__dirname, '..', 'assets', 'images', folder.directory);
  for (const fileName of fs.readdirSync(directoryPath)) {
    const imageUrl = `assets/images/${folder.directory}/${fileName}`;
    if (PRODUCTS.some((product) => product.imageUrl === imageUrl)) {
      continue;
    }
    const name = path.basename(fileName, path.extname(fileName)).replace(/[-_]/g, ' ');
    const pricing = EXTRA_PRICING[imageUrl] || {
      price: 5.99,
      rating: 4.6,
      blurb: `A useful ${folder.category.replace('_', ' ')} addition for your aquarium.`
    };
    const id = nextProductId++;
    PRODUCTS.push({
      id,
      name,
      category: folder.category,
      price: pricing.price,
      rating: pricing.rating,
      stock: 20,
      imageUrl,
      blurb: pricing.blurb,
      isNew: NEW_PRODUCT_NAMES.has(name),
      sellerId: ((id - 1) % SELLERS.length) + 1
    });
  }
}


// ---------------------------------------------------------------------
// Push everything into Firestore.
// sellerId / seller id are converted to STRINGS here because Firebase
// Auth user ids (uid) are strings — keeping every seller id as a string,
// built-in or user-created, keeps the whole app consistent.
// ---------------------------------------------------------------------
async function seed() {
  console.log(`Seeding ${SELLERS.length} sellers...`);
  for (const seller of SELLERS) {
    await db.collection('sellers').doc(String(seller.id)).set({
      ...seller,
      id: String(seller.id),
    });
  }

  console.log(`Seeding ${PRODUCTS.length} products...`);
  for (const product of PRODUCTS) {
    await db.collection('products').doc(String(product.id)).set({
      ...product,
      sellerId: String(product.sellerId),
      isNew: product.isNew || false,
    });
  }

  // Powers the auto-increment used when a user adds a new product
  // (see add_product_screen.dart / the Firestore transaction there).
  const maxId = PRODUCTS.reduce((max, p) => Math.max(max, p.id), 0);
  await db.collection('counters').doc('products').set({ lastId: maxId });

  console.log('Done! Seeded sellers, products, and the products id counter.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
