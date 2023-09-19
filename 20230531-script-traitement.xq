declare option output:method "csv";
declare option output:csv "header=yes, separator=semicolon";

(: Les données Vasserot ont été préalablement mises en BDD ("AdressesVasserot") grâce au fichier 20220519_alpage-adresses-vasserot.geojson :)
let $Vasserot := collection('AdressesVasserot')

(: Liste des noms de voies Vasserot :)
let $voies := $Vasserot/json/features/_/properties/nom__entier

(: Liste des numéros de voies Vasserot :)
let $numeros := $Vasserot/json/features/_/properties/num__voies
 
(: Liste des notices à géocoder :)
let $notices := json:doc('20230705-export-curl-person-caa.json')/json/hits/hits/_ 

(: Liste des lieux trouvés dans les notices :)
let $lieux := $notices/__source/content/addressInformation/address/_

(: Jointure entre la table des collections et celle des collectionneurs grâce au CSV généré précédemment :)
let $csv_collections := csv:doc("csv_tablecollections.csv", map {'header':true(), 'separator': ';'})
let $collections_csv := for $ligne in $csv_collections//record
  let $uuid_collectionneur := $ligne/uuid_collectionneur/text()
  let $uuid_collection := $ligne/uuid_collection/text()
  let $titre := $ligne/titre_collection/text()
  return concat($uuid_collectionneur, ",", $uuid_collection, ",", $titre)

(: Traiter chaque lieu :)
let $lignes := for $lieu (:at $pos:) in $lieux

    (: La ville du  lieu :)
let $ville := $lieu/place//prefLabels//value/text()

     (:le conceptpath :)    
     let $ville_fr := $lieu//place//conceptPath
      where starts-with($ville_fr,"/Europe/France")
      let $latAGORHA := tokenize($lieu//place//geoPoint, ",")[1]
      let $longAGORHA := tokenize($lieu//place//geoPoint, ",")[2]
      
      
    (: L'adresse du lieu :)
    let $adresse := $lieu/label/value

    (: Ne conserver que les lieux qui possèdent une adresse en France :)
    (: where ($ville = "Paris" and $adresse) or not($ville = "Paris") :)
    where $adresse and $ville_fr
   
    (: Remonter à la notice du lieu :)
    let $notice := $lieu/ancestor::__source 
    let $SourceNoticeUuid := $notice/internal/sourceNoticeUuid
    where not($SourceNoticeUuid)
     
     (:Récupérer la vignette pour l'infobulle:)
    let $vignette := $notice/content/mediaInformation/prefPicture/thumbnail/text()
    
    (: Récupérer l'UUID de la notice :)
    let $uuid := $notice/internal/uuid/text()

    (: Récupérer le titre de la notice :)
    (: let $titreNotice := $notice/internal/digest/displayLabelLink/text() :)
    let $titreNotice := $notice/internal/digest/title/text()
    
    (: Récupérer le type de personne :)
    let $typePersonne := $notice/internal/digest/personType/text()
    
    (: Récupérer l'activité de la personne :)
    let $activitePersonne := $notice//activityInformation//activity/_/type/thesaurus//prefLabels//value
    let $activiteComment := if(matches(string-join($activitePersonne, ', '), "(marchand|antiquaire|négociant)", "i")) then $activitePersonne/ancestor::_/comment/text() else ""
    let $activitePersonne := if(not($activitePersonne)) then "Non renseigné" else string-join(distinct-values($activitePersonne), ", ")
    where not($typePersonne= "collectivité" and $activitePersonne = "Non renseigné")
    
    (: Récupérer la date de début de la notice :)
    let $dateDebut := replace($lieu/date/startDateComputed/text(),' AD','')
    let $prefixeDebut := $lieu/date/start/prefix/thesaurus/prefLabels/_/value/text()

    (: Récupérer la date de fin de la notice :)
    let $dateFin := replace($lieu/date/endDateComputed/text(),' AD','')
    let $prefixeFin := $lieu/date/end/prefix/thesaurus/prefLabels/_/value/text()
    
    
    let $anneeDebut := tokenize($dateDebut,"-")[1]
    where not ($anneeDebut > "1939")
    let $anneeFin := tokenize($dateFin, "-")[1]
    (:where $anneeFin <= "1939" :)
    
    let $anneeDebutInt := xs:integer($anneeDebut)
 
  let $anneeFinInt := xs:integer($anneeFin)
  let $anneeDebutPrefixee :=
  if ($prefixeDebut = "Vers") then ""
  else if (not($prefixeDebut)) then ""
  else if ($prefixeDebut = "Avant") then $anneeDebutInt + 90
  else if($prefixeFin = "Après" and (not($prefixeDebut) and $anneeDebutInt <= ($anneeFinInt - 100)))  then  $anneeDebutInt + 90
  else if($prefixeFin = "Avant" and (not($prefixeDebut) and $anneeDebutInt <= ($anneeFinInt  -100)))  then  $anneeDebutInt
  
  else ""

 (:for $i in $prefixeFin:)    
 
  let $anneeFinPrefixee :=
  if ($prefixeFin = "Vers") then ""
  (:else if ($prefixeFin = "Avant") then $anneeFinInt + 95:)
  else if (not($prefixeFin)) then ""
  else if ($prefixeFin = "Après") then $anneeFinInt - 90
  (:else if ($prefixeFin = "Vers") then "":)
  else if($prefixeDebut = "Après" and (not($prefixeFin) and $anneeFinInt >= ($anneeDebutInt  +100)))  then  $anneeFinInt - 90
  else if($prefixeDebut = "Avant" and (not($prefixeFin) and $anneeFinInt >= ($anneeDebutInt  +100)))  then  $anneeFinInt
  else ""
   
  let $anneeDebut := 
  if($anneeDebutPrefixee)
  then tokenize(string-join(($anneeDebut, '#', $anneeDebutPrefixee)), '#')[2]
  else $anneeDebut
  
  let $anneeFin := 
  if($anneeFinPrefixee)
  then tokenize(string-join(($anneeFin, '#', $anneeFinPrefixee)), '#')[2]
  else $anneeFin

    (: Récupérer le type de lieu :)
    let $typeLieu := $lieu/type//prefLabels//value/text()
    let $typeLieu := if(not($typeLieu)) then "Non renseigné" else $typeLieu
    (:where $typeLieu = "Non renseigné":)
    
    (: Récupérer le code postal :)
    let $codePostal := $lieu/postalCode/text()
    let $codePostal := replace($codePostal,' ; 75007','')
    let $codePostal := replace($codePostal, " ","")
    
    
    
    (: Nettoyer les balises HTML de l'adresse du lieu :)
    (: Enlever les balises paragraphes :)
    let $adresse := replace($adresse,'&lt;/?p&gt;','')
    (: Enlever les balises strong :)
    let $adresse := replace($adresse,'&lt;/?strong&gt;','')
    let $adresse := replace($adresse,'&lt;/?strong( style="[^"]+")?&gt;','','') 
    (: Enlever les balises span style="..." :)
    let $adresse := replace($adresse,'&lt;/?span( style="[^"]+")?&gt;','')
    (: Enlever les balises h4 class="ql-align-center" :)   
    let $adresse := replace($adresse,'&lt;/?h4( class="ql-align-center")?&gt;','')
    (: Enlever les balises br :)
    let $adresse := replace($adresse,'&lt;br&gt;','')
    let $adresse := replace($adresse,'&amp;nbsp;','')      
    
    (: Préparer les informations de la voie à partir de l'adresse :)

    let $voie := 

        (: Si l'adresse contient certains termes :)
        if(matches($adresse,'^(Hôtel|Palais|Les Arts|Musée|La Chartreuse|Grand carré|Magasin Chinois19|Service des Mines25)')) 

        (: Retirer ces termes plus tout ce se trouve jusqu'à la virgule plus les éventuels numéros de la rue qui suivent :)
        then replace($adresse,'^(Hôtel|Palais|Les Arts|Musée|La Chartreuse|Grand carré|Magasin Chinois19|Service des Mines25)[^,]*, ([0-9- ,]+)?','')

        (: Sinon retirer les numéros de la rue :)
        else replace($adresse,'^(n°)?[0-9- ,]+(et 3bis, )?','')
    
    (: Récupérer uniquement le texte de la voie :)
      let $voieGeo := replace($voie, "^ | $","")
      let $voieGeo := replace($voieGeo, "&lt;/?p&gt;", "")
      let $voieGeo := replace($voieGeo, '&lt;/?span( style="[^"]+")?&gt;', '')
      let $voieGeo := replace($voieGeo, "&lt;/?br&gt;", " ")
      let $voieGeo := replace($voieGeo, "&lt;/?em&gt;", " ")
      let $voieGeo := replace($voieGeo, "\[illisible\] |\[\?\]", " ")
      
      let $voieGeo := replace($voieGeo, '\[Lieu de naissance\] |Château de Saverne, |\(n° ancien\)|\(n<sup style="color: black;">o</sup> ancien\)| \[rue disparue\]|villa Araucaria, |Château de la Colline de Marseille-Veyre \(actuel Château Cantini, Lycée Marseilleveyre\)| \(adresse renseignée par le catalogue de la vente Thibeaudeau 1857\)|Clos Hébert, |« Samten Dzong », anciennement : route de Nice, aujourd’hui : | \(ancien hôtel d.Evreux\)$|«Au Pavillon de Hanovre», |« Au Pavillon de Hanovre », |, rue du Bac', "")
      (: let $voieGeo := replace($voieGeo, "(\d) .*\(actuelle (.*)\)", "$1 $2") :)
      let $voieGeo := replace($voieGeo, ".*\(actuel (.*)\).*", "$1")
      let $voieGeo := replace($voieGeo, ".*\(actuelle (.*)\).*", "$1")
      let $voieGeo := replace($voieGeo, ".*\(actuellement : (.*)\).*", "$1")
      let $voieGeo := replace($voieGeo, ".*\(act\. (.*)\).*", "$1")
      let $voieGeo := replace($voieGeo, "(\d\d) .*\(aujourd'hui (.*)\)", "$1 $2")
      let $voieGeo := replace($voieGeo, ".*\(aujourd'hui: (.*)\)", "$1")
      let $voieGeo := replace($voieGeo, ".*\(aujourd'hui : (.*)\)", "$1")
      let $voieGeo := replace($voieGeo, ".*aujourd’hui (.*)", "$1")
      let $voieGeo := replace($voieGeo, ".*aujourd'hui (.*)", "$1")
      let $voieGeo := replace($voieGeo, ".*devenue en 1919, (.*)\)", "$1")
      (: let $voieGeo := replace($voieGeo, ".*\(aujourd'hui : (.*)\)", "$1") :)
      let $voieGeo := replace($voieGeo, "Avenue Georges V", "Avenue George V")
      let $voieGeo := replace($voieGeo, 'lieu-dit "Bélesbat"', 'lieu-dit Belesbat')
      let $voieGeo := replace($voieGeo, "^\s|^\s+|\s$|\s+$|,$", "")
      let $voieGeo := replace($voieGeo, "rue de la Boétie", "rue la Boétie")
      let $voieGeo := replace($voieGeo, "Lafitte", "Laffitte")
      let $voieGeo := replace($voieGeo, ",", " ")
      let $voieGeo := replace($voieGeo, "\s+", " ")
      let $voieGeo := replace($voieGeo, "‘|’", "'")
      let $voieGeo := replace($voieGeo, "é|è|ë|ê|É|È|Ê|Ë", "e")
      let $voieGeo := replace($voieGeo, "ô|ö|ò|Ò|Ô|Ö", "o")
      let $voieGeo := replace($voieGeo, "à|ä|â|Â|Ä|À", "a")
      let $voieGeo := replace($voieGeo, "ù|ü|û|Û|Ü|Ù", "u")
      let $voieGeo := replace($voieGeo, "ì|ï|î|Ì|Ï|Î", "u")
      let $voieGeo := replace($voieGeo, "str\.|Str\.", "strasse")
      let $voieGeo := replace($voieGeo, "ß|ẞ", "ss")
      let $voieGeo := replace($voieGeo, "square Messine", "rue Docteur-Lancereaux")
      let $voieGeo := replace($voieGeo, "rue de Boulard", "rue Boulard")
      let $voieGeo2 := replace($voieGeo, "\s", "+")
      
     (:Villes pour géocodage:)
    let $villeGeo := replace($ville, " \(Autriche\)| \(Hesse\)", '')
    let $villeGeo := replace($villeGeo, "^ | $|  $", "")
    let $villeGeo := replace($villeGeo, ",", " ")
    let $villeGeo := replace($villeGeo, "\s\s", " ")
    let $villeGeo := replace($villeGeo, "‘|’", "'")
    let $villeGeo := replace($villeGeo, "é|è|ë|ê|ế|É|È|Ê|Ë", "e")
    let $villeGeo := replace($villeGeo, "ô|ö|ò|ố|ồ|ở|ọ|ō|Ò|Ô|Ö", "o")
    let $villeGeo := replace($villeGeo, "à|ä|â|á|Â|Ä|À", "a")
    let $villeGeo := replace($villeGeo, "ù|ü|û|ự|Û|Ü|Ù", "u")
    let $villeGeo := replace($villeGeo, "ì|ï|î|ì|Ì|Ï|Î", "i")
    let $villeGeo := replace($villeGeo, "ý", "y")
    let $villeGeo := replace($villeGeo, "Đ", "D")
    let $villeGeo := replace($villeGeo, "ß|ẞ", "ss")
    let $villeGeo := replace($villeGeo, "\s", "+")         
    
    (: Récupérer le numéro de la voie selon le même mode que précédemment:)
    let $numero := if(matches($adresse,'^(Hôtel|Palais|Les Arts|Musée|La Chartreuse|Grand carré)')) 
        then replace(tokenize($adresse,',\s+')[2],'^(n°)?([0-9]+)?.+','$2') 
        else if(matches($adresse,'Magasin Chinois19|Service des Mines25')) then replace($adresse,'.*(\d+).*', "$1" )
        else replace($adresse,'^(n°)?([0-9]+)?.+','$2') 
    
    let $adresseGeo:= 
    if($numero) then string-join(($numero, $voieGeo2), "+")
    else if(not($numero)) then $voieGeo2 else ""
    
    (: Récupérer les lignes Vasserot dont le nom de la voie est identique à celui du lieu :)    
    let $refVoies := if($ville = "Paris") then $Vasserot/json/features/_[matches(replace(properties/nom__entier,'-',' '),replace($voie,'-',' '),'i')]
    
    (: Vérifier s'il existe une ligne Vasserot avec le même nom de voie et le même numéro  :)
    let $refExacte := $refVoies[properties/num__voies = $numero]
    
    (: Récupérer les coordonnées du lieu :)
    let $coordonnees := 
    
        (: S'il se trouve une ligne avec la même voie et le même numéro :)
        if($refExacte) 
        
        (: Récupérer les coordonnées de cette ligne :)
        then string-join($refExacte/geometry/coordinates/_/_/text(),',')

        (: Sinon, s'il y a plusieurs numéros mais aucun ne correspond à celui du lieu :)
        else if(count($refVoies) > 1)
        
             (: Récupérer les coordonnées du numéro médian parmi ceux existant :) 
             then let $m := floor(count($refVoies) div 2)
                  return string-join($refVoies[$m]/geometry/coordinates/_/_/text(),',')              

        (: Sinon récupérer la les coordonnées de l'unique ligne correspondant à la voie :)
        else string-join($refVoies[1]/geometry/coordinates/_/_/text(),',')
    
    let $coordonnees := tokenize($coordonnees, ",")
    let $latVasserot := if (count ($coordonnees) > 1) then $coordonnees[2] else ""
    let $longVasserot := if (count ($coordonnees) > 1) then $coordonnees[1] else ""
    
    (: Requête BAN :)
    let $reqBAN :=    
if(not($latVasserot) and $numero and $voieGeo2 and $codePostal and $villeGeo) then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;housenumber=", $numero,"&amp;street=",$voieGeo2,"&amp;postcode=",$codePostal,"&amp;city=", $villeGeo)))
else if(not($latVasserot) and $numero and $voieGeo2 and $villeGeo and not($codePostal)) then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;housenumber=", $numero,"&amp;street=",$voieGeo2,"&amp;city=", $villeGeo)))
else if(not($latVasserot) and not($numero) and $voieGeo2 and $villeGeo and not($codePostal)) then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;street=",$voieGeo2,"&amp;city=", $villeGeo)))
else if(not($latVasserot) and not($numero) and $voieGeo2 and $villeGeo and $codePostal) then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;street=",$voieGeo2,"&amp;postcode=", $codePostal, "&amp;city=", $villeGeo)))
else  if(not($latVasserot) and not($numero) and not($voieGeo2) and $codePostal and $ville)  then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;postcode=",$codePostal,"&amp;city=", $villeGeo)))
else  if(not($latVasserot) and not($numero) and not($voieGeo2) and not($codePostal) and $ville)  then http:send-request(<http:request method='get'/>, string-join(("https://api-adresse.data.gouv.fr/search/?q=", $adresseGeo ,"&amp;city=", $villeGeo)))
else ""


           let $latitudeBAN := $reqBAN[2]//features/_[1]//coordinates/_[2]/text()
           let $longitudeBAN := $reqBAN[2]//features/_[1]//coordinates/_[1]/text()
           let $score := $reqBAN[2]//features/_[1]/properties/score/text()
          
           let $latitude := if($latVasserot) then $latVasserot
           else if(not($latVasserot) and $latitudeBAN) then $latitudeBAN
           else if(not($latVasserot) and not($latitudeBAN) and $latAGORHA)  then $latAGORHA
           else if(not($latVasserot) and not($latitudeBAN) and not($latAGORHA)) then ""
           
           let $longitude := if($longVasserot) then $longVasserot
           else if(not($longVasserot) and $longitudeBAN) then $longitudeBAN
           else if(not($longVasserot) and not($longitudeBAN) and $longAGORHA)  then $longAGORHA
           else if(not($longVasserot) and not($longitudeBAN) and not($longAGORHA)) then ""
           
           let $score := $reqBAN[2]//features/_[1]/properties/score/text()
           
    (: Préparer le commentaire sur l'approximation ou non des coordonnées :)
    let $commentaire := if((not($refExacte) and count ($coordonnees)>1)) then 'localisation approximative'
    
    (:Jointure avec le fichier des collections :)
    let $collection :=
      for $collection in $collections_csv
      where tokenize($collection, ",")[1] = $uuid
      return string-join((tokenize($collection, ',')[2], tokenize($collection, ',')[3]), "/")
    let $collections := string-join($collection, "§")
    
    let $collection1 := tokenize($collections, "§")[1]
    let $collection2 := tokenize($collections, "§")[2]
    
    let $uuid_collection_1 := tokenize($collection1, "/")[1]
    let $nom_collection_1 := tokenize($collection1, "/")[2] 
    let $uuid_collection_2 := tokenize($collection2, "/")[1]
    let $nom_collection_2 := tokenize($collection2, "/")[2] 
    
    return
    
    (: Structure de la sortie :)
    <record>
      <notice>{$uuid}</notice>
      <adresse>{$adresse}</adresse>
      <adresseGeo>{$adresseGeo}</adresseGeo>
      <adresseGeo2>{$voieGeo}</adresseGeo2>
      <numero>{$numero}</numero>
      <voie>{$voie}</voie>
      <codePostal>{$codePostal}</codePostal>
      <ville>{$ville}</ville>
      <typeLieu>{$typeLieu}</typeLieu>
      <dateDebut>{$dateDebut}</dateDebut>
      <anneeDebut>{$anneeDebut}</anneeDebut>
      <dateFin>{$dateFin}</dateFin>
      <anneeFin>{$anneeFin}</anneeFin>
      <titreNotice>{$titreNotice}</titreNotice>
      <typePersonne>{$typePersonne}</typePersonne>
      <activitePersonne>{$activitePersonne}</activitePersonne>
      <activiteComment>{$activiteComment}</activiteComment>
      <latitude>{$latitude}</latitude>
      <longitude>{$longitude}</longitude>
      <score>{$score}</score>
      <vignette>{$vignette}</vignette>
      <commentaire>{$commentaire}</commentaire>
      <uuid_collection_1>{$uuid_collection_1}</uuid_collection_1>
      <nom_collection_1>{$nom_collection_1}</nom_collection_1>
      <uuid_collection_2>{$uuid_collection_2}</uuid_collection_2>
      <nom_collection_2>{$nom_collection_2}</nom_collection_2>
    </record>
        
 
 (: Retourner tous les lieux traités :)   
 return <csv>{$lignes}</csv>