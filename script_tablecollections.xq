declare option output:method "csv";
declare option output:csv "header=yes, separator=semicolon";

let $notices := collection("20230421-export-collection-caa")/notices/_

(:On boucle sur les notices:)
let $lignes := 
  for $notice in $notices
  let $statut := $notice/internal/status/text()
  let $uuid_notice := $notice/internal/uuid/text()
  let $sourceNoticeUuid := $notice//sourceNoticeUuid/text()
 
  let $titre := $notice//internal/digest/title/text()
  let $related_person := $notice//relatedPerson/_

    (:pour chaque personne du bloc related_person de chaque notice:)
  for $pers in $related_person 
    let $activites_related_person := $pers/role/thesaurus/_
    let $roles := for $role in $activites_related_person
      return $role/prefLabels/_/value/text()
      
     let $roles := string-join($roles, ",")
      
      
    let $uuid_related_person := $pers//person/ref/text()
(:Que les notices publiées:)
where not($sourceNoticeUuid)

return 
<record>
  <uuid_collectionneur>{$uuid_related_person}</uuid_collectionneur>
  <uuid_collection>{$uuid_notice}</uuid_collection>
  <statut_notice>{$statut}</statut_notice>
  <titre_collection>{$titre}</titre_collection>
  <activite_personne>{$roles}</activite_personne>
</record>

return 
  <csv>{$lignes}</csv>