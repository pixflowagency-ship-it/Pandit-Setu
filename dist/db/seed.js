import 'dotenv/config';
import { db } from '../db/index.js';
import { poojas } from '../db/schema/poojas.js';
import { products } from '../db/schema/products.js';
async function seed() {
    console.log('🧹 Clearing existing poojas and products...');
    await db.delete(poojas);
    await db.delete(products);
    const poojaEntries = [
        {
            "title": "Griha Pravesh Pooja",
            "slug": "griha-pravesh-pooja",
            "description": "Authentic Griha Pravesh Pooja ritual performed by 2 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Ghar aur Jeevan se related Pooja.",
            "basePrice": "5100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1621252179027-94459d278660?w=500"
        },
        {
            "title": "Vastu Shanti Pooja",
            "slug": "vastu-shanti-pooja",
            "description": "Authentic Vastu Shanti Pooja ritual performed by 5 To 7 experienced Vedic Pandit(s). Duration: 1-7 Days. Category: Ghar aur Jeevan se related Pooja.",
            "basePrice": "51000.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500"
        },
        {
            "title": "Satyanarayan Katha",
            "slug": "satyanarayan-katha",
            "description": "Authentic Satyanarayan Katha ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Ghar aur Jeevan se related Pooja.",
            "basePrice": "2100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500"
        },
        {
            "title": "Lakshmi Pooja",
            "slug": "lakshmi-pooja",
            "description": "Authentic Lakshmi Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Ghar aur Jeevan se related Pooja.",
            "basePrice": "3100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500"
        },
        {
            "title": "Kuber Pooja",
            "slug": "kuber-pooja",
            "description": "Authentic Kuber Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Ghar aur Jeevan se related Pooja.",
            "basePrice": "3100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500"
        },
        {
            "title": "Vivah (Marriage Pooja)",
            "slug": "vivah-marriage-pooja",
            "description": "Authentic Vivah (Marriage Pooja) ritual performed by 2 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Sanskar (Life Events).",
            "basePrice": "21000.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=500"
        },
        {
            "title": "Namkaran Sanskar",
            "slug": "namkaran-sanskar",
            "description": "Authentic Namkaran Sanskar ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Sanskar (Life Events).",
            "basePrice": "3100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1544717305-2782549b5136?w=500"
        },
        {
            "title": "Mundan Sanskar",
            "slug": "mundan-sanskar",
            "description": "Authentic Mundan Sanskar ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Sanskar (Life Events).",
            "basePrice": "2100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1583307878879-9a4c4e78b7e5?w=500"
        },
        {
            "title": "Upanayan (Janeu Sanskar)",
            "slug": "upanayan-janeu-sanskar",
            "description": "Authentic Upanayan (Janeu Sanskar) ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Sanskar (Life Events).",
            "basePrice": "5100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        },
        {
            "title": "Annaprashan",
            "slug": "annaprashan",
            "description": "Authentic Annaprashan ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Sanskar (Life Events).",
            "basePrice": "2100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1519689680058-324335c77eba?w=500"
        },
        {
            "title": "Navgraha Shanti Pooja",
            "slug": "navgraha-shanti-pooja",
            "description": "Authentic Navgraha Shanti Pooja ritual performed by 3 experienced Vedic Pandit(s). Duration: 1 day. Category: Dosh Nivaran & Special Pooja.",
            "basePrice": "11000.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        },
        {
            "title": "Kaal Sarp Dosh Pooja",
            "slug": "kaal-sarp-dosh-pooja",
            "description": "Authentic Kaal Sarp Dosh Pooja ritual performed by 5 experienced Vedic Pandit(s). Duration: 3 Day. Category: Dosh Nivaran & Special Pooja.",
            "basePrice": "25000.00",
            "durationMinutes": 1080,
            "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500"
        },
        {
            "title": "Mangal Dosh Pooja",
            "slug": "mangal-dosh-pooja",
            "description": "Authentic Mangal Dosh Pooja ritual performed by 3 experienced Vedic Pandit(s). Duration: 1 Day. Category: Dosh Nivaran & Special Pooja.",
            "basePrice": "11000.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500"
        },
        {
            "title": "Mahamrityunjaya Jaap",
            "slug": "mahamrityunjaya-jaap",
            "description": "Authentic Mahamrityunjaya Jaap ritual performed by 7 experienced Vedic Pandit(s). Duration: 1 To 7. Category: Dosh Nivaran & Special Pooja.",
            "basePrice": "2100",
            "durationMinutes": 120,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        },
        {
            "title": "Pitra Dosh Nivaran",
            "slug": "pitra-dosh-nivaran",
            "description": "Authentic Pitra Dosh Nivaran ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Dosh Nivaran & Special Pooja.",
            "basePrice": "5100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500"
        },
        {
            "title": "Diwali Lakshmi Ganesh Pooja",
            "slug": "diwali-lakshmi-ganesh-pooja",
            "description": "Authentic Diwali Lakshmi Ganesh Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1-3 Hour. Category: Festival Special Pooja.",
            "basePrice": "5100.00",
            "durationMinutes": 180,
            "imageUrl": "https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500"
        },
        {
            "title": "Ganesh Chaturthi Pooja",
            "slug": "ganesh-chaturthi-pooja",
            "description": "Authentic Ganesh Chaturthi Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 5 Day. Category: Festival Special Pooja.",
            "basePrice": "2100",
            "durationMinutes": 1800,
            "imageUrl": "https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500"
        },
        {
            "title": "Navratri Pooja",
            "slug": "navratri-pooja",
            "description": "Authentic Navratri Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 9 Day. Category: Festival Special Pooja.",
            "basePrice": "2100",
            "durationMinutes": 3240,
            "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500"
        },
        {
            "title": "Durga Pooja",
            "slug": "durga-pooja",
            "description": "Authentic Durga Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Festival Special Pooja.",
            "basePrice": "3100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500"
        },
        {
            "title": "Shivratri Pooja",
            "slug": "shivratri-pooja",
            "description": "Authentic Shivratri Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Festival Special Pooja.",
            "basePrice": "5100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        },
        {
            "title": "Vishwakarma Pooja",
            "slug": "vishwakarma-pooja",
            "description": "Authentic Vishwakarma Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Business Pooja.",
            "basePrice": "3100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1621252179027-94459d278660?w=500"
        },
        {
            "title": "Kuber Upasana",
            "slug": "kuber-upasana",
            "description": "Authentic Kuber Upasana ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Business Pooja.",
            "basePrice": "5100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500"
        },
        {
            "title": "Ganesh Pooja",
            "slug": "ganesh-pooja",
            "description": "Authentic Ganesh Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Daily / Regular Pooja.",
            "basePrice": "2100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500"
        },
        {
            "title": "Hanuman Pooja",
            "slug": "hanuman-pooja",
            "description": "Authentic Hanuman Pooja ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Daily / Regular Pooja.",
            "basePrice": "2100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        },
        {
            "title": "Sundarkand Path",
            "slug": "sundarkand-path",
            "description": "Authentic Sundarkand Path ritual performed by 5 experienced Vedic Pandit(s). Duration: 1 Day. Category: Daily / Regular Pooja.",
            "basePrice": "15000.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500"
        },
        {
            "title": "Rudrabhishek",
            "slug": "rudrabhishek",
            "description": "Authentic Rudrabhishek ritual performed by 1 experienced Vedic Pandit(s). Duration: 1 Day. Category: Daily / Regular Pooja.",
            "basePrice": "3100.00",
            "durationMinutes": 360,
            "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500"
        }
    ];
    await db.insert(poojas).values(poojaEntries);
    const productEntries = [
        {
            "name": "तांबे का कलश",
            "description": "Sacred तांबे का कलश (1 pcs) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नारियल",
            "description": "Sacred नारियल (2 pcs) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "2 pcs",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "आम के पत्ते",
            "description": "Sacred आम के पत्ते (11 pcs) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मौली / कलावा",
            "description": "Sacred मौली / कलावा (1 roll) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "1 roll",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल कपड़ा",
            "description": "Sacred लाल कपड़ा (1 meter) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "1 meter",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अक्षत (चावल)",
            "description": "Sacred अक्षत (चावल) (1 kg) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "रोली / कुमकुम",
            "description": "Sacred रोली / कुमकुम (100 gm) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हल्दी",
            "description": "Sacred हल्दी (100 gm) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सुपारी",
            "description": "Sacred सुपारी (21 pcs) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सिक्का",
            "description": "Sacred सिक्का (11 pcs) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गंगाजल",
            "description": "Sacred गंगाजल (1 bottle) for Kalash Sthapana. Requirement: Required.",
            "price": "250",
            "category": "Kalash Sthapana",
            "badge": "Essential",
            "samagri": [
                "1 bottle",
                "Kalash Sthapana"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "रोली",
            "description": "Sacred रोली (100 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कुमकुम",
            "description": "Sacred कुमकुम (100 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हल्दी पाउडर",
            "description": "Sacred हल्दी पाउडर (100 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हल्दी गांठ",
            "description": "Sacred हल्दी गांठ (100 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चंदन",
            "description": "Sacred चंदन (50 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल चंदन",
            "description": "Sacred लाल चंदन (50 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सफेद चंदन",
            "description": "Sacred सफेद चंदन (50 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अक्षत",
            "description": "Sacred अक्षत (2 kg) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जौ",
            "description": "Sacred जौ (1 kg) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "तिल सफेद",
            "description": "Sacred तिल सफेद (250 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "250 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "तिल काला",
            "description": "Sacred तिल काला (250 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "250 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गेहूं",
            "description": "Sacred गेहूं (1 kg) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मूंग",
            "description": "Sacred मूंग (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चना",
            "description": "Sacred चना (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मसूर",
            "description": "Sacred मसूर (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पंचरत्न",
            "description": "Sacred पंचरत्न (1 packet) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 packet",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पंचमेवा",
            "description": "Sacred पंचमेवा (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "बताशा",
            "description": "Sacred बताशा (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मिश्री",
            "description": "Sacred मिश्री (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "खील",
            "description": "Sacred खील (500 gm) for मुख्य पूजा सामग्री. Requirement: Required.",
            "price": "350",
            "category": "मुख्य पूजा सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "मुख्य पूजा सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "फूल माला",
            "description": "Sacred फूल माला (5 pcs) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गुलाब",
            "description": "Sacred गुलाब (2 kg) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गेंदा फूल",
            "description": "Sacred गेंदा फूल (2 kg) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कमल का फूल",
            "description": "Sacred कमल का फूल (5 pcs) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "बेलपत्र",
            "description": "Sacred बेलपत्र (108 leaves) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "108 leaves",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दूर्वा",
            "description": "Sacred दूर्वा (5 bundle) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "5 bundle",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "तुलसी पत्ता",
            "description": "Sacred तुलसी पत्ता (1 bundle) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "1 bundle",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पान के पत्ते",
            "description": "Sacred पान के पत्ते (21 pcs) for पुष्प एवं पत्ते. Requirement: Required.",
            "price": "150",
            "category": "पुष्प एवं पत्ते",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "पुष्प एवं पत्ते"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नारियल",
            "description": "Sacred नारियल (11 pcs) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "केला",
            "description": "Sacred केला (2 dozen) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "2 dozen",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सेब",
            "description": "Sacred सेब (2 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "संतरा",
            "description": "Sacred संतरा (2 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अनार",
            "description": "Sacred अनार (1 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अंगूर",
            "description": "Sacred अंगूर (1 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मिठाई",
            "description": "Sacred मिठाई (2 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लड्डू",
            "description": "Sacred लड्डू (1 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पेड़ा",
            "description": "Sacred पेड़ा (1 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पंजीरी",
            "description": "Sacred पंजीरी (1 kg) for फल एवं प्रसाद. Requirement: Required.",
            "price": "200",
            "category": "फल एवं प्रसाद",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "फल एवं प्रसाद"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दूध",
            "description": "Sacred दूध (2 litre) for पंचामृत. Requirement: Required.",
            "price": "180",
            "category": "पंचामृत",
            "badge": "Essential",
            "samagri": [
                "2 litre",
                "पंचामृत"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दही",
            "description": "Sacred दही (1 kg) for पंचामृत. Requirement: Required.",
            "price": "180",
            "category": "पंचामृत",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "पंचामृत"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "घी",
            "description": "Sacred घी (500 gm) for पंचामृत. Requirement: Required.",
            "price": "180",
            "category": "पंचामृत",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "पंचामृत"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शहद",
            "description": "Sacred शहद (250 gm) for पंचामृत. Requirement: Required.",
            "price": "180",
            "category": "पंचामृत",
            "badge": "Essential",
            "samagri": [
                "250 gm",
                "पंचामृत"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शक्कर / मिश्री",
            "description": "Sacred शक्कर / मिश्री (500 gm) for पंचामृत. Requirement: Required.",
            "price": "180",
            "category": "पंचामृत",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "पंचामृत"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हवन कुंड",
            "description": "Sacred हवन कुंड (1 pcs) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हवन सामग्री",
            "description": "Sacred हवन सामग्री (2 kg) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "हवन समिधा",
            "description": "Sacred हवन समिधा (5 bundle) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "5 bundle",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "आम की लकड़ी",
            "description": "Sacred आम की लकड़ी (5 kg) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "5 kg",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कपूर",
            "description": "Sacred कपूर (100 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शुद्ध घी",
            "description": "Sacred शुद्ध घी (1 kg) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जौ",
            "description": "Sacred जौ (500 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "काला तिल",
            "description": "Sacred काला तिल (250 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "250 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सफेद तिल",
            "description": "Sacred सफेद तिल (250 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "250 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चावल",
            "description": "Sacred चावल (500 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लौंग",
            "description": "Sacred लौंग (50 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "इलायची",
            "description": "Sacred इलायची (50 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गुग्गुल",
            "description": "Sacred गुग्गुल (100 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लोबान",
            "description": "Sacred लोबान (100 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शक्कर",
            "description": "Sacred शक्कर (500 gm) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सूखा नारियल / गोला",
            "description": "Sacred सूखा नारियल / गोला (5 pcs) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नवग्रह समिधा",
            "description": "Sacred नवग्रह समिधा (1 set) for हवन सामग्री. Requirement: Required.",
            "price": "450",
            "category": "हवन सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "हवन सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मिट्टी के दीपक",
            "description": "Sacred मिट्टी के दीपक (51 pcs) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "51 pcs",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पीतल का दीपक",
            "description": "Sacred पीतल का दीपक (2 pcs) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "2 pcs",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "रुई बत्ती",
            "description": "Sacred रुई बत्ती (1 packet) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "1 packet",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "घी",
            "description": "Sacred घी (500 gm) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सरसों तेल",
            "description": "Sacred सरसों तेल (500 ml) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "500 ml",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कपूर",
            "description": "Sacred कपूर (100 gm) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "धूप",
            "description": "Sacred धूप (1 packet) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "1 packet",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अगरबत्ती",
            "description": "Sacred अगरबत्ती (2 packet) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "2 packet",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "धूपदानी",
            "description": "Sacred धूपदानी (1 pcs) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "आरती थाली",
            "description": "Sacred आरती थाली (1 pcs) for दीपक एवं आरती. Requirement: Required.",
            "price": "220",
            "category": "दीपक एवं आरती",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "दीपक एवं आरती"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गणेश जी की मूर्ति / प्रतिमा",
            "description": "Sacred गणेश जी की मूर्ति / प्रतिमा (1 pcs) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दूर्वा",
            "description": "Sacred दूर्वा (21 bundle) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "21 bundle",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मोदक / लड्डू",
            "description": "Sacred मोदक / लड्डू (21 pcs) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सिंदूर",
            "description": "Sacred सिंदूर (50 gm) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल फूल",
            "description": "Sacred लाल फूल (21 pcs) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सुपारी",
            "description": "Sacred सुपारी (5 pcs) for गणेश पूजा. Requirement: Required.",
            "price": "300",
            "category": "गणेश पूजा",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "गणेश पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शिवलिंग",
            "description": "Sacred शिवलिंग (1 pcs) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "बेलपत्र",
            "description": "Sacred बेलपत्र (108 leaves) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "108 leaves",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "भस्म",
            "description": "Sacred भस्म (50 gm) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "धतूरा",
            "description": "Sacred धतूरा (5 pcs) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "आक के फूल",
            "description": "Sacred आक के फूल (21 pcs) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दूध",
            "description": "Sacred दूध (2 litre) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "2 litre",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गंगाजल",
            "description": "Sacred गंगाजल (1 bottle) for शिव पूजा. Requirement: Required.",
            "price": "320",
            "category": "शिव पूजा",
            "badge": "Essential",
            "samagri": [
                "1 bottle",
                "शिव पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल चुनरी",
            "description": "Sacred लाल चुनरी (2 pcs) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "2 pcs",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल कपड़ा",
            "description": "Sacred लाल कपड़ा (2 meter) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "2 meter",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल फूल",
            "description": "Sacred लाल फूल (2 kg) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "2 kg",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सिंदूर",
            "description": "Sacred सिंदूर (100 gm) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कुमकुम",
            "description": "Sacred कुमकुम (100 gm) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "श्रृंगार सामग्री",
            "description": "Sacred श्रृंगार सामग्री (1 set) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल चूड़ी",
            "description": "Sacred लाल चूड़ी (1 set) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "बिंदी",
            "description": "Sacred बिंदी (1 packet) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "1 packet",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मेहंदी",
            "description": "Sacred मेहंदी (100 gm) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "100 gm",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "इत्र",
            "description": "Sacred इत्र (1 bottle) for देवी पूजा. Requirement: Required.",
            "price": "380",
            "category": "देवी पूजा",
            "badge": "Essential",
            "samagri": [
                "1 bottle",
                "देवी पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "तुलसी दल",
            "description": "Sacred तुलसी दल (1 bundle) for विष्णु / सत्यनारायण. Requirement: Required.",
            "price": "290",
            "category": "विष्णु / सत्यनारायण",
            "badge": "Essential",
            "samagri": [
                "1 bundle",
                "विष्णु / सत्यनारायण"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पीला कपड़ा",
            "description": "Sacred पीला कपड़ा (2 meter) for विष्णु / सत्यनारायण. Requirement: Required.",
            "price": "290",
            "category": "विष्णु / सत्यनारायण",
            "badge": "Essential",
            "samagri": [
                "2 meter",
                "विष्णु / सत्यनारायण"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पीले फूल",
            "description": "Sacred पीले फूल (1 kg) for विष्णु / सत्यनारायण. Requirement: Required.",
            "price": "290",
            "category": "विष्णु / सत्यनारायण",
            "badge": "Essential",
            "samagri": [
                "1 kg",
                "विष्णु / सत्यनारायण"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "केले",
            "description": "Sacred केले (2 dozen) for विष्णु / सत्यनारायण. Requirement: Required.",
            "price": "290",
            "category": "विष्णु / सत्यनारायण",
            "badge": "Essential",
            "samagri": [
                "2 dozen",
                "विष्णु / सत्यनारायण"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पंचमेवा",
            "description": "Sacred पंचमेवा (500 gm) for विष्णु / सत्यनारायण. Requirement: Required.",
            "price": "290",
            "category": "विष्णु / सत्यनारायण",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "विष्णु / सत्यनारायण"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गेहूं",
            "description": "Sacred गेहूं (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चावल",
            "description": "Sacred चावल (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मूंग",
            "description": "Sacred मूंग (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "उड़द",
            "description": "Sacred उड़द (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मसूर",
            "description": "Sacred मसूर (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चना",
            "description": "Sacred चना (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जौ",
            "description": "Sacred जौ (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "काला तिल",
            "description": "Sacred काला तिल (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सफेद तिल",
            "description": "Sacred सफेद तिल (500 gm) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "500 gm",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नवग्रह वस्त्र",
            "description": "Sacred नवग्रह वस्त्र (1 set) for नवग्रह पूजा. Requirement: Required.",
            "price": "500",
            "category": "नवग्रह पूजा",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "नवग्रह पूजा"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लाल कपड़ा",
            "description": "Sacred लाल कपड़ा (5 meter) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 meter",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पीला कपड़ा",
            "description": "Sacred पीला कपड़ा (5 meter) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 meter",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "सफेद कपड़ा",
            "description": "Sacred सफेद कपड़ा (5 meter) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 meter",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "मौली / कलावा",
            "description": "Sacred मौली / कलावा (2 roll) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "2 roll",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जनेऊ",
            "description": "Sacred जनेऊ (21 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "आसन",
            "description": "Sacred आसन (5 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पूजा चौकी",
            "description": "Sacred पूजा चौकी (2 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "2 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "थाली",
            "description": "Sacred थाली (5 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कटोरी",
            "description": "Sacred कटोरी (11 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लोटा",
            "description": "Sacred लोटा (2 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "2 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "चम्मच",
            "description": "Sacred चम्मच (5 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "5 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "घंटी",
            "description": "Sacred घंटी (1 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शंख",
            "description": "Sacred शंख (1 pcs) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पंचपात्र",
            "description": "Sacred पंचपात्र (1 set) for वस्त्र एवं अन्य. Requirement: Required.",
            "price": "400",
            "category": "वस्त्र एवं अन्य",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "वस्त्र एवं अन्य"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नवग्रह यंत्र",
            "description": "Sacred नवग्रह यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गणेश यंत्र",
            "description": "Sacred गणेश यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "लक्ष्मी यंत्र",
            "description": "Sacred लक्ष्मी यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कुबेर यंत्र",
            "description": "Sacred कुबेर यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "रुद्राक्ष",
            "description": "Sacred रुद्राक्ष (1 set) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शालिग्राम",
            "description": "Sacred शालिग्राम (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गोमती चक्र",
            "description": "Sacred गोमती चक्र (11 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कौड़ी",
            "description": "Sacred कौड़ी (21 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "अष्टगंध",
            "description": "Sacred अष्टगंध (50 gm) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "केसर",
            "description": "Sacred केसर (5 gm) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "5 gm",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जायफल",
            "description": "Sacred जायफल (11 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "जावित्री",
            "description": "Sacred जावित्री (25 gm) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "25 gm",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "दालचीनी",
            "description": "Sacred दालचीनी (50 gm) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "50 gm",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "गोमती चक्र",
            "description": "Sacred गोमती चक्र (11 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "11 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कौड़ी",
            "description": "Sacred कौड़ी (21 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "21 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "शालिग्राम",
            "description": "Sacred शालिग्राम (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "रुद्राक्ष",
            "description": "Sacred रुद्राक्ष (1 set) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "पारद शिवलिंग",
            "description": "Sacred पारद शिवलिंग (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "स्फटिक शिवलिंग",
            "description": "Sacred स्फटिक शिवलिंग (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "नवग्रह यंत्र",
            "description": "Sacred नवग्रह यंत्र (1 set) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 set",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "श्री यंत्र",
            "description": "Sacred श्री यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "कुबेर यंत्र",
            "description": "Sacred कुबेर यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        },
        {
            "name": "वास्तु यंत्र",
            "description": "Sacred वास्तु यंत्र (1 pcs) for विशेष सामग्री. Requirement: Required.",
            "price": "650",
            "category": "विशेष सामग्री",
            "badge": "Essential",
            "samagri": [
                "1 pcs",
                "विशेष सामग्री"
            ],
            "imageUrl": "",
            "isActive": true
        }
    ];
    await db.insert(products).values(productEntries);
    console.log('✅ Seed data inserted successfully: 26 poojas & 156 items!');
}
seed().catch((err) => {
    console.error('🚨 Seed failed:', err);
    process.exit(1);
});
//# sourceMappingURL=seed.js.map