var map;
var tiles;


//Cette fonction charge la carte
function chargerCarte(){


tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {maxZoom: 19, minZoom: 4, attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'}),latlng = L.latLng(46.227638, 2.213749)//.addTo(map);
        map= L.map('map', {center: latlng, zoom: 6, layers: [tiles]});
        isMap=true        
  }      


// Cette fonction affiche la carte en utilisant des données GeoJSON
function montrer(geojson_CAA) {
    InitialisationCarte(geojson_CAA);
  }
// Cette fonction cache la carte actuelle  
  function cacher() {
      map.off();
      map.remove();
      chargerCarte();
    }
// Appel initial pour charger la carte
chargerCarte();

// Appel de la fonction InitialisationCarte avec des données GeoJSON (geojson_CAA)
InitialisationCarte(geojson_CAA);

// Clique sur le premier bouton de sélection de couche
$(".leaflet-control-layers-selector")[0].click();

// Cette fonction initialise la carte avec des clusters et des marqueurs
function InitialisationCarte(geojson_CAA){ 
// Crée des clusters de marqueurs
var clusterAdresses = L.markerClusterGroup(
	{
		iconCreateFunction: function (clusterAdresses){
		var childCount = clusterAdresses.getChildCount();
		var c= ' marker-cluster-';
		if (childCount < 10){
			c += 'small';
		}
		else if (childCount < 100){
			c += 'medium';
		}
		else {
			c += 'large';
		}
		return new L.DivIcon({html: '<div><span>'+ childCount + '</span></div>',
		className: 'marker-cluster' + c, iconSize: new L.Point(40,40)});
		},
		polygonOptions: {
		  color: '#ffffff',
				  opacity : 50,
				  stroke: false
			}
			}
),
// Crée des groupes de fonctionnalités pour différents types de marqueurs
all = L.featureGroup.subGroup(clusterAdresses),
collectionneurs = L.featureGroup.subGroup(clusterAdresses),
collecteurs = L.featureGroup.subGroup(clusterAdresses),
marchands = L.featureGroup.subGroup(clusterAdresses)

// Fonction pour le contenu des popups des marqueurs
 function popupContent(feature, layer){
	layer.on({
		'onclick': function(e) {
		   this.openPopup();
		  },
	   }
	   )

	   var datePresence;
                if (feature.properties.anneeDebut !== "" && feature.properties.anneeFin !== "" ){
                  datePresence = feature.properties.anneeDebut + " - " + feature.properties.anneeFin
                }
               else if(feature.properties.anneeDebut !== "" && feature.properties.anneeFin === ""){
                        datePresence = feature.properties.anneeDebut + " - "
               }
               else if(feature.properties.anneeDebut === "" && feature.properties.anneeFin !== ""){
                 datePresence =  " - "+ feature.properties.anneeFin
               }
               else if(feature.properties.anneeDebut === "" && feature.properties.anneeFin === ""){
                 datePresence = "Indéterminé"
               }
			 
			   
			   		var popupContent = "<div style='width: 100%'><img src='"+feature.properties.vignette+"'  style='object-fit: cover; display:block; margin-left:auto; margin-right: auto; box-shadow: 2px 2px 5px black; border-radius : 2px'/><p><h3  style='text-align: center'>"+feature.properties.titreNotice + "</h3></p><table><tr><td><i class='fas fa-map-pin'></i> "+
			   		feature.properties.adresse+"</tr></td><tr><td>"+feature.properties.code_postal+"</tr></td><tr><td>"+feature.properties.ville+"</tr></td><tr><td><i class='fas fa-calendar-day'></i> "+ datePresence + "</tr></td><tr><td><i class='fas fa-briefcase'></i>  "+feature.properties.activitePersonne+"</tr></td><table>"+"<a id='lienAgorhaPopup' title='Voir la notice AGORHA' href='https://agorha.inha.fr/ark:/54721/"+ feature.properties.uuid + "' target='_blank'><input id='lienAgorha' style='display:block; width: 200px' class='button' type='submit' value='Voir sur AGORHA'></div></div>"
			   		+feature.properties.nom_collection1+"</tr></td><tr><td>"+feature.properties.nom_collection2

				  layer.bindPopup(popupContent);    
		}

		
// Ajoute des marqueurs à la carte pour différents types de données GeoJSON
L.geoJson(geojson_CAA, {
	onEachFeature: popupContent,
	pointToLayer: function(feature, latlng) {
// Crée des marqueurs de cercle pour chaque entité GeoJSON	
    return L.circleMarker(latlng, 
			{color: 'crimson',
			weight:1.5})
		}}).addTo(all)

L.geoJson(geojson_CAA, {
		onEachFeature: popupContent,
		pointToLayer: function(feature, latlng) {
		  var activite = feature.properties.activitePersonne
		  if (activite.match(/collectionneur/gi) || activite.match(/collectionneuse/gi)){
			return new L.circleMarker(latlng, {
			  color: 'crimson',
			  weight: 1.5
			});
		  }
		}
	  }).addTo(collectionneurs)

L.geoJson(geojson_CAA, {
		onEachFeature: popupContent,
		pointToLayer: function(feature, latlng) {
		  var activite = feature.properties.activitePersonne
		  if (activite.match(/collecteur/gi)) {
			return new L.circleMarker(latlng, {
			  color: 'crimson',
			  weight: 1.5
			});
		  }
		}
	  }).addTo(collecteurs)

L.geoJson(geojson_CAA, {
		onEachFeature: popupContent,
		pointToLayer: function(feature, latlng) {
		  var activite = feature.properties.activitePersonne
		  if (activite.match(/marchand/gi)) {
			return new L.circleMarker(latlng, {
			  color: 'crimson',
			  weight: 1.5
			});
		  }
		}
	  }).addTo(marchands)

// Ajoute des groupes de fonctionnalités à la carte (Panneau de contrôle)
var overlays = {
		"Tous": all,
		"Collectionneurs": collectionneurs,
		"Collecteurs": collecteurs,
		"Marchands": marchands
	};

	L.control.layers( overlays,null, {collapsed: false}).addTo(map);

	clusterAdresses.addTo(map);      

    $(".leaflet-control-layers-selector")[0].click();


}
// Cette partie du code réagit à l'événement "document ready"
$(document).ready(function(){

    /*JCC: INITIALISATION DU CURSEUR */
   
       var debuts = [];
               for (let i=0; i<geojson_CAA.features.length; i++){
               var lieu = geojson_CAA.features[i]
               var d= lieu["properties"]["anneeDebut"]
               d= d*1
               if(d>0){
               debuts.push(d)
               }
               }
               var min_debuts = Math.min.apply(null,debuts)
   
   var fins = [];
               for (let i=0; i<geojson_CAA.features.length; i++){
               var lieu = geojson_CAA.features[i]
               var d= lieu["properties"]["anneeFin"]
               d= d*1
               if(d>0){
               fins.push(d)
               }
               }
               var max_fins = Math.max.apply(null,fins)
   
   $( "#slider-range" ).slider({
       
     // mode intervalle
     range: true,
     // valeur minimum
     min: 1700,
     // valeur maximum
     max: 1939,
     // valeurs de départ
     values: [ min_debuts, max_fins ],
     // action si changement de valeur
   
      slide: function( event, ui ) {
       $('.ui-slider-handle').eq(0).html('<span>'+ui.values[0]+'</span>')
       $('.ui-slider-handle').eq(1).html('<span>'+ui.values[1]+'</span>')
     },
   
     stop: function( event, ui ) {
   
       var debut = ui.values[0];
       var fin = ui.values[1];
       var newGeoJson = {
                   "type": "Feature Collection",
                   "features": []
                 };
   
       for (let i = 0; i < geojson_CAA["features"].length; i++) {
   
         var lieu = geojson_CAA["features"][i]
   
         if(!lieu['properties']) continue;
   
         var d = lieu['properties']['anneeDebut']
         var f = lieu['properties']['anneeFin']
   
         if((d <= debut && f <= fin && f >= debut) && d !== "" ||  (d <= fin &&  d>= debut && f >= fin) && d !== "" || d >= debut && f <= fin && d !== ""){
   
           newGeoJson['features'].push(lieu);
   
         }
          else if(debut === 1700 && fin === 1939 ){
           newGeoJson['features'].push(lieu);
           }   
       }
   
       // repérer les boutons qui sont cochés / leur état
       
      var index = {};
       $(".leaflet-control-layers-selector").each(function(i) {
      if (this.checked) {
          index = i
          
      }   
   
   })
   
   // Récupérer le niveau de zoom et les coordonnées pour les réafficher à l'exactitude
    
       var currentZoom =  map.getZoom()
       var currentView = map.getCenter();
       var lat = Object.values(JSON.stringify(currentView.lat))
       var lng = Object.values(JSON.stringify(currentView.lng))
       var currentLat = lat.join('')
       var currentLng = lng.join('')
       console.log(currentZoom)
   
       cacher();
       console.log(newGeoJson)
   
       InitialisationCarte(newGeoJson);
   
             map.setView([currentLat, currentLng], currentZoom,
             {
               animate: false,
               duration: 0})
     
    $(".leaflet-control-layers-selector")[index].click();
    
       // afficher la valeur de l'année dans le curseur
       $('.ui-slider-handle').eq(0).html('<span>'+ui.values[0]+'</span>')
       $('.ui-slider-handle').eq(1).html('<span>'+ui.values[1]+'</span>')
       $('#resume').html("<b>Le résultat de votre recherche est de "+ newGeoJson.features.length +' lieu(x)</b>');
   
       },
       create: function(){
   
         // à l'initialisation, afficher la valeur de l'année dans le curseur
   
         $('.ui-slider-handle').eq(0).html('<span>'+$("#slider-range").slider('values',0)+'</span>');
         $('.ui-slider-handle').eq(1).html('<span>'+$("#slider-range").slider('values',1)+'</span>');
         $('#resume').html("<b>La carte répertorie actuellement "+geojson_CAA.features.length+' lieu(x)</b>');
       }
   
   });
   
   })