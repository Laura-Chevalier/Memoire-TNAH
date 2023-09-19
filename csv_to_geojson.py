# On importe les modules CSV et JSON
import csv, json
# Import de la librairie GeoJSON et des différents modules pour permettre le formatage des données en GeoJSON
from geojson import Feature, FeatureCollection, Point


# Documentation : https://stackoverflow.com/questions/48586647/python-script-to-convert-csv-to-geojson
# On définit une liste vide de propriétés
features = []
# On ouvre le fichier CSV de l'annuaire dont les données ont été harmonisées
with open('20230720-export-basex-geocoded.csv', newline='', encoding="utf-8") as csvfile:
    # Avec la méthode .reader() on retourne un objet : le fichier lu
    reader = csv.reader(csvfile, delimiter=';')
    # Pour chaque colonne dans le fichier lu, on définit le champ de chaque colonne et son numéro d'index
    for row in reader :
        uuid = row[0]
        adresse = row[1]
        code_postal = row[2]
        ville = row[3]
        typeLieu= row[4]
        dateDebut= row[5]
        anneeDebut = row[6]
        dateFin= row[7]
        anneeFin = row[8]
        titreNotice = row[9]
        typePersonne = row[10]
        activitePersonne = row[11]
        activiteComment = row[12]
        latitude = row[13]
        longitude = row[14]
        score = row[15]
        vignette = row[16]
        commentaire = row[17]
        uuid_collection1 = row[18]
        nom_collection1 = row[19]
        uuid_collection2 = row[20]
        nom_collection2 = row[21]
        #idAdresse = row[16]
        # Pour chacun de ces champs   #, idAdresse
        for uuid, adresse, code_postal, ville, typeLieu, dateDebut, anneeDebut, dateFin, anneeFin, titreNotice, typePersonne, activitePersonne, activiteComment, longitude, latitude, score, vignette, commentaire, uuid_collection1, nom_collection1, uuid_collection2, nom_collection2 in reader:
            # les latitudes et longitudes sont définies comme des coordonnées géographiques et des 'float' (décimaux)
            latitude, longitude = map(float, (latitude, longitude))
            # On ajoute à la liste des propriétés
            features.append(
                # Une propriété (Feature) ou chaque "Feature" représente une ligne/institution différente
                Feature(
                    # La latitude et la longitude sont définies comme des coordonnées de type "Point"
                    geometry = Point((latitude, longitude)),
                    # On définit pour chaque propriété ses caractéristiques selon la syntaxe JSON : une clé (key") associée à la valeur de la cellule dans chaque colonne
                    # définie en amont
                    properties = {
                        'uuid': uuid,
                        'adresse': adresse,
                        'code_postal': code_postal,
                        'ville': ville,
                        'typeLieu': typeLieu,
                        'dateDebut': dateDebut,
                        'anneeDebut': anneeDebut,
                        'dateFin': dateFin,
                        'anneeFin': anneeFin,
                        'titreNotice': titreNotice,
                        'typePersonne' : typePersonne,
                        'activitePersonne' : activitePersonne,
                        'activiteComment': activiteComment,
                        'vignette': vignette,
                        'commentaire': commentaire,
                        "uuid_collection1": uuid_collection1,
                        "nom_collection1": nom_collection1,
                        "uuid_collection2": uuid_collection2,
                        "nom_collection2": nom_collection2
                    }
                )
            )

# On ajoute l'ensemble de ces propriétés dans une "collection de propriétés"
collection = FeatureCollection(features)
# on ouvre un fichier GeoJSON en mode écriture
with open("data_map_caa.geojson", "w", encoding="utf-8") as f:
    # On écrit dans ce fichier le contenu de cette "collection de propriétés"
    f.write('%s' % collection)


with open("data_map_caa.geojson", 'r', encoding="utf-8") as f:
    data = f.read()
    with open("data_js.js", "w", encoding="utf-8") as js_file :
        content = "var geojson_CAA ="+data
        js_file.write(content)