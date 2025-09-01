# addData.py

from app import create_app, db   # use your factory or app instance
from app.models import MasterAreas  # adjust import if needed

def insert_master_areas():
    areas = [
        ("Nigdi-Prdhikaran", "निगडी - प्राधिकरण"),
        ("Akurdi", "आकुर्डी"),
        ("Chinchwadgaon", "चिंचवडगांव"),
        ("Thergaon", "थेरगांव"),
        ("Kiwale", "किवळे"),
        ("Ravet", "रावेत"),
        ("Mamurdi", "मामुर्डी"),
        ("Wakad", "वाकड"),
        ("Punawale", "पुनावळे"),
        ("Bopkhel", "बोपखेल"),
        ("Dapodi-Fugewadi", "दापोडी फुगेवाडी"),
        ("Talawade", "तळवडे"),
        ("Morwadi", "मोरवाडी"),
        ("Bhosari", "भोसरी"),
        ("Chikhali", "चिखली"),
        ("Charholi", "च-होली"),
        ("Moshi", "मोशी"),
        ("Pimprigaon", "पिंपरीगांव"),
        ("Kharalwadi", "खराळवाडी"),
        ("Kasarwadi", "कासारवाडी"),
        ("Kalewadi-Rahatani", "काळेवाडी रहाटणी"),
        ("Chinchwad-Station", "चिंचवड स्टेशन"),
        ("Pimple-Nilakh", "पिंपळे निलख"),
        ("Pimple-Saudagar", "पिंपळे सौदागर"),
        ("Pimple-Gurav", "पिंपळे गुरव"),
        ("New-Sangvi", "नवी सांगवी"),
        ("Old-Sangvi", "जुनी सांगवी"),
        ("Sambhaji-Nagar", "संभाजीनगर"),
        ("Sant-Tukaram-Nagar", "संत तुकाराम नगर"),
        ("Nehru-Nagar", "नेहरूनगर"),
        ("Pimpri-Camp", "पिंपरी कॅम्प"),
        ("Yamuna-Nagar", "यमुनानगर"),
        ("Masulkar-Colony", "मासुळकर कॉलनी"),
        ("Dighi", "दिघी"),
        ("Tathawade", "ताथवडे"),
        ("Dudulgaon", "डुडूळगांव"),
        ("Wadmukhwadi", "वडमुखवाडी"),
        ("AII-PCMC", "पिं.चिं. शहर"),
        ("Walhekar Wadi", "वाल्हेकरवाडी"),
        ("Bhatnagar", "भाटनगर"),
        ("Jadhavwadi-KudalWadi", "जाधववाडी-कुदळवाडी"),
        ("Indrayani Nagar", "इंद्रायणी नगर"),
        ("Rupi Nagar", "रुपीनगर"),
        ("Kalbhor Nagar", "काळभोरनगर"),
        ("Chinchwade Nagar", "चिंचवडेनगर"),
        ("Shivtej Nagar Chikhali", "शिवतेज नगर चिखली"),
    ]

    objects = [MasterAreas(name=name, description=desc) for name, desc in areas]
    db.session.bulk_save_objects(objects)
    db.session.commit()
    print(f"✅ Inserted {len(objects)} master_areas successfully!")

if __name__ == "__main__":
    app = create_app()  # if you use app factory pattern
    with app.app_context():
        insert_master_areas()
