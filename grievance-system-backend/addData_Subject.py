# addSubjects.py

from app import create_app, db   # adjust if you import app directly
from app.models import MasterSubjects  # make sure MasterSubject model exists

def insert_master_subjects():
    subjects = [
        ("रस्त्यावरील खड्डयांबाबत", "Pot Holes"),
        ("सार्वजनिक शौचालय साफसफाईबाबत", "Cleaning of Public Toilets"),
        ("अनाधिकृत टपऱ्या / हातगाड्या / फेरीवाल्यांबाबत", "Unauthorised Stalls & Hawkers"),
        ("अनाधिकृत मोबाईल टॉवरबाबत", "Unauthorised Mobile Tower"),
        ("किटकनाशक फवारणी", "Spraying Of Pesticides"),
        ("रस्ते दुरूस्ती", "Road repairing"),
        ("पाणी समस्या", "Water problem"),
        ("ड्रेनेज तुंबलेबाबत", "Drainage blockage"),
        ("रस्त्यावरील विद्युत दिव्यांबाबत", "Street lights"),
        ("परिसर साफसफाई / कचरा उचलणेबाबत", "Area Cleaning / Garbage lifting"),
        ("ध्वनी प्रदुषणाबाबत", "Sound Pollution"),
        ("इतर", "Other"),
        ("मृत जनावर", "Dead animal"),
        ("कचराकुंडी साफ नाहीत", "Dustbins not cleaned"),
        ("कचरा गाडीबाबत", "Garbage vehicle not arrived"),
        ("सार्वजनिक स्वच्छतागृहातील विदयुत दिव्याबाबत", "No electricity in public toilet"),
        ("सार्वजनिक स्वच्छतागृहातील पाणी समस्याबाबत", "No water supply in public toilet"),
        ("सार्वजनिक स्वच्छतागृहातील साफसफाईबाबत", "Public toilet blockage-cleaning"),
        ("गतिरोधक", "Speed Breaker"),
        ("कमी दाबाने पाणी पुरवठा", "Low Water Pressure"),
        ("दुषित पाणी पुरवठा", "Contaminated Water Supply"),
        ("अनियमित पाणी पुरवठा", "Irregular Water Supply"),
        ("पाईपलाईन लीकेज", "Pipeline Leakage"),
        ("पेविंग ब्लॉक", "Paving Block"),
        ("वृक्ष छाटणी", "Tree Cutting"),
        ("फुटपाथ दुरुस्ती बाबत", "Regarding pavement repair"),
        ("फुटपाथ साफसफाई बाबत", "Clean Sidewalk"),
        ("भटक्या कुत्र्यांसाठी जन्म नियंत्रण बाबत", "Birth Control for Stray Dogs"),
        ("आजारी किंवा जखमी भटका कुत्रा बाबत", "Sick or Injured Stray Dog"),
        ("भटक्या कुत्र्याने चावा बाबत", "Bite by Stray Dog"),
        ("मोठे मृत जनावरांची विल्हेवाट लावणे बाबत", "Disposal of large dead animals"),
        ("रेबीज ग्रस्त श्वानांची तक्रार बाबत", "Complaints of rabies dogs"),
    ]

    objects = [MasterSubjects(name=eng, description=mar) for mar, eng in subjects]
    db.session.bulk_save_objects(objects)
    db.session.commit()
    print(f"✅ Inserted {len(objects)} master_subjects successfully!")

if __name__ == "__main__":
    app = create_app()  # if you use factory pattern
    with app.app_context():
        insert_master_subjects()
