#!/bin/env bash

# Standardwerte setzen
CPTS=""

# Argumente parsen
while getopts "c:" opt; do
  case $opt in
    c) CPTS="$OPTARG" ;;
    *) echo "Ungültige Option" >&2; exit 1 ;;
  esac
done

# Prüfen, ob CPTs angegeben wurden
if [[ -z "$CPTS" ]]; then
  echo "Fehlende CPTs! Nutzung: $0 -c cpt1,cpt2,..."
  exit 1
fi

# SQL WHERE-Bedingung für die CPTs generieren
CPTS_SQL=$(echo "$CPTS" | sed "s/,/','/g")
CPTS_SQL="('$CPTS_SQL')"

# Export CPTs
wp db query "SELECT * FROM wp_posts WHERE post_type IN $CPTS_SQL" --allow-root > cpts.sql

# Export Postmeta (benutzerdefinierte Felder)
wp db query "SELECT * FROM wp_postmeta WHERE post_id IN (SELECT ID FROM wp_posts WHERE post_type IN $CPTS_SQL)" --allow-root >> cpts.sql

# Export Taxonomien (Beziehungen zwischen CPTs und Taxonomien)
wp db query "SELECT * FROM wp_term_relationships WHERE object_id IN (SELECT ID FROM wp_posts WHERE post_type IN $CPTS_SQL)" --allow-root >> cpts.sql

# Export Taxonomie-Informationen
wp db query "SELECT * FROM wp_term_taxonomy WHERE term_taxonomy_id IN (SELECT term_taxonomy_id FROM wp_term_relationships WHERE object_id IN (SELECT ID FROM wp_posts WHERE post_type IN $CPTS_SQL))" --allow-root >> cpts.sql

# Export Begriffe (Terms)
wp db query "SELECT * FROM wp_terms WHERE term_id IN (SELECT term_id FROM wp_term_taxonomy WHERE term_taxonomy_id IN (SELECT term_taxonomy_id FROM wp_term_relationships WHERE object_id IN (SELECT ID FROM wp_posts WHERE post_type IN $CPTS_SQL))))" --allow-root >> cpts.sql

echo "Expo          rt abgeschlossen: cpts.sql"
