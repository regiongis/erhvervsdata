CREATE OR REPLACE FUNCTION cvr.flyt_fad(komkode integer, startdato date, slutdato date)
  RETURNS TABLE(status text, "cvr-nummer" bigint, "p-nummer" bigint, hovedbranche character varying, navn character varying, "fuldt ansvarlige deltagere" character varying, kommunekode smallint, vejnavn character varying, husnummer bigint, postnummer bigint, postdistrikt character varying, emailadresse character varying, startdato timestamp without time zone, geom geometry, "indlæst dato" date)
LANGUAGE SQL
AS $$
SELECT
DISTINCT 
  
    flyt.flyttemoenster,
    stam.virksomhed_cvrnr,
    flyt.pnr,
    stam.hovedbranche_tekst,
    stam.navn_tekst,
    fad.navn,
    flyt.kommune_kode,
    flyt.beliggenhedsadresse_vejnavn,
    flyt.belig_adresse_husnummerfra,
    flyt.beliggenhedsadresse_postnr,
    flyt.belig_adresse_postdistrikt,
    stam.email_kontaktoplysning,
    stam.livsforloeb_startdato,
    flyt.geom,
    flyt.indlaest_dato
FROM (
       SELECT 'Tilflytter'::text AS flyttemoenster,
            a.pnr,
            a.kommune_kode,
            a.beliggenhedsadresse_vejnavn,
            a.belig_adresse_husnummerfra,
            a.beliggenhedsadresse_postnr,
            a.belig_adresse_postdistrikt,
			a.geom,
            a.indlaest_dato
        FROM (
               SELECT
                 pnr,
                 beliggenhedsadresse_gyldigfra,
                 kommune_kode,
                 beliggenhedsadresse_vejnavn,
                 belig_adresse_husnummerfra,
                 beliggenhedsadresse_postnr,
                 belig_adresse_postdistrikt,
                 geom,
                 indlaest_dato
               FROM cvr.cvr_prod_enhed_geo_hist_adresser
               WHERE beliggenhedsadresse_gyldigfra BETWEEN startdato AND slutdato
             ) AS a
          LEFT JOIN (
                       SELECT
                          pnr,
                          beliggenhedsadresse_gyldigfra,
                          kommune_kode,
                          beliggenhedsadresse_vejnavn,
                          belig_adresse_husnummerfra,
                          beliggenhedsadresse_postnr,
                          belig_adresse_postdistrikt,
						  geom,
                          indlaest_dato
                       FROM cvr.cvr_prod_enhed_geo_hist_adresser c
                       WHERE beliggenhedsadresse_gyldigfra = (
                         SELECT MAX(beliggenhedsadresse_gyldigfra)
                         FROM cvr.cvr_prod_enhed_geo_hist_adresser d
                         WHERE c.pnr = d.pnr AND d.beliggenhedsadresse_gyldigfra < startdato
                       )
                     ) AS b ON a.pnr = b.pnr
          WHERE a.kommune_kode = komkode AND a.kommune_kode <> b.kommune_kode

        UNION ALL

        SELECT 'Fraflytter'::text AS flyttemoenster,
          a.pnr,
          a.kommune_kode,
          a.beliggenhedsadresse_vejnavn,
          a.belig_adresse_husnummerfra,
          a.beliggenhedsadresse_postnr,
          a.belig_adresse_postdistrikt,
		  a.geom,
          a.indlaest_dato
        FROM (
               SELECT
                 pnr,
                 beliggenhedsadresse_gyldigfra,
                 kommune_kode,
                 beliggenhedsadresse_vejnavn,
                 belig_adresse_husnummerfra,
                 beliggenhedsadresse_postnr,
                 belig_adresse_postdistrikt,
		  		 geom,
                 indlaest_dato
               FROM cvr.cvr_prod_enhed_geo_hist_adresser
               WHERE beliggenhedsadresse_gyldigfra BETWEEN startdato AND slutdato
             ) AS a
          LEFT JOIN (
                      SELECT
                        pnr,
                        beliggenhedsadresse_gyldigfra,
                        kommune_kode,
                        beliggenhedsadresse_vejnavn,
                        belig_adresse_husnummerfra,
                        beliggenhedsadresse_postnr,
                        belig_adresse_postdistrikt,
					    geom,
                        indlaest_dato
                      FROM cvr.cvr_prod_enhed_geo_hist_adresser c
                      WHERE beliggenhedsadresse_gyldigfra = (
                        SELECT MAX(beliggenhedsadresse_gyldigfra)
                        FROM cvr.cvr_prod_enhed_geo_hist_adresser d
                        WHERE c.pnr = d.pnr AND d.beliggenhedsadresse_gyldigfra < startdato
                      )
                     ) AS b ON a.pnr = b.pnr
        WHERE b.kommune_kode = komkode AND a.kommune_kode <> b.kommune_kode

        UNION ALL

        SELECT 'Nystartet'::text AS flyttemoenster,
          a.pnr,
          a.kommune_kode,
          a.beliggenhedsadresse_vejnavn,
          a.belig_adresse_husnummerfra,
          a.beliggenhedsadresse_postnr,
          a.belig_adresse_postdistrikt,
		  a.geom,
          a.indlaest_dato
        FROM cvr.cvr_prod_enhed_geo_stam a
        WHERE a.kommune_kode = komkode AND a.livsforloeb_startdato BETWEEN startdato AND slutdato

        UNION ALL

        SELECT 'Ophørt'::text AS flyttemoenster,
          a.pnr,
          a.kommune_kode,
          a.beliggenhedsadresse_vejnavn,
          a.belig_adresse_husnummerfra,
          a.beliggenhedsadresse_postnr,
          a.belig_adresse_postdistrikt,
		  a.geom,
          a.indlaest_dato
        FROM cvr.cvr_prod_enhed_geo_stam a
        WHERE a.kommune_kode = komkode AND a.livsforloeb_ophoersdato BETWEEN startdato AND slutdato) as flyt

LEFT JOIN cvr.cvr_prod_enhed_geo_stam stam ON flyt.pnr = stam.pnr
LEFT JOIN (SELECT substr(array_agg(navn)::text, 2, length(array_agg(navn)::text)-2) AS navn,
                  cvrnr
           FROM (SELECT DISTINCT navn, cvrnr FROM cvr.cvr_fad) navne
           GROUP BY cvrnr) fad
           ON fad.cvrnr = stam.virksomhed_cvrnr

ORDER BY stam.virksomhed_cvrnr

$$;

