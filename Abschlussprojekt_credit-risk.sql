-- Projekt A: Datenanalyse für einen Finanzdienstleister 

/*Motivation:

Ein Finanzdienstleistungsunternehmen vergibt Konsumentenkredite an Privatpersonen.
Der Vorstand ist unzufrieden mit zwei zentralen Geschäftsprozessen:

1. Kreditüberwachung
- Alle Kreditnehmer werden aktuell gleich intensiv überwacht, unabhängig von ihrem individuellen Risiko
- Das führt zu hohen Kosten, unnötigem Aufwand und ineffizientem Ressourceneinsatz

2. Kreditvergabe und Kreditpricing
- Es besteht der Verdacht, dass interne Vergaberichtlinien nicht konsequent eingehalten werden
- Kredite könnten nicht risikogerecht vergeben oder bepreist sein
-Besonders riskante Kreditnehmer könnten zu hohe Kreditsummen oder zu günstige Zinssätze erhalten*/

/* Ziel:
 dieses Projekts ist es, durch eine systematische Datenanalyse die Kreditrisikosteuerung eines Finanzdienstleistungsunternehmens zu verbessern.
 Kreditnehmer werden anhand relevanter Merkmale in Risikokategorien mit niedrigem, mittlerem und hohem Kreditrisiko eingeteilt. 
 Diese Einteilung bildet die Grundlage für eine risikobasierte Kreditüberwachung mit angepasster Überwachungsintensität. 
 Zusätzlich wird analysiert, ob Kreditsummen und Zinssätze dem tatsächlichen Risiko der Kreditnehmer entsprechen. 
 Die Ergebnisse liefern dem Management eine objektive Entscheidungsgrundlage zur effizienteren Steuerung von Risiken und Prozessen. 
 */
 
 -- ===================================================================================================================================
 
-- Databank kreieren
CREATE DATABASE credit_risk_dataset; 

-- kreierte Database benutzen
USE credit_risk_dataset;


-- Schritt 1: Tabelle erstellen 
CREATE TABLE IF NOT EXISTS credit_risk ( 
person_age INT, 
person_income INT, 
person_home_ownership VARCHAR(20), 
person_emp_length DOUBLE NULL, 
loan_intent VARCHAR(30), 
loan_grade VARCHAR(5), 
loan_amnt INT, 
loan_int_rate DOUBLE NULL, 
loan_status INT, 
loan_percent_income DOUBLE, 
cb_person_default_on_file VARCHAR(5), 
cb_person_cred_hist_length INT 
);

-- Kontrolle
SELECT * FROM credit_risk;    -- kontroliere ob die Tabelle richtig erstellt wurde


-- Schritt 2: Daten importieren (Pfad anpassen und vorher SET GLOBAL local_infile = 1; ausführen!) 
SET GLOBAL local_infile = 1;        -- Erlaubt das Laden von Dateien vom eigenen Computer

LOAD DATA LOCAL INFILE "C:/projekt/credit_risk_dataset.csv" 
INTO TABLE credit_risk 
FIELDS TERMINATED BY ','                -- Spalten sind durch Kommas getrennt
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS           -- Überspringt die Kopfzeile der CSV
(person_age, person_income, person_home_ownership,  
@emp_length, loan_intent, loan_grade, loan_amnt,  
@int_rate, loan_status, loan_percent_income,  
cb_person_default_on_file, cb_person_cred_hist_length) 
SET  
person_emp_length = NULLIF(@emp_length, ''),   -- Wenn leer → NULL 
loan_int_rate = NULLIF(@int_rate, '');   -- Sonst → Wert übernehmen


-- Spalten unbennen 
-- Die Spalten heißen jetzt verständlich und einheitlich auf Deutsch                
ALTER TABLE credit_risk 
CHANGE person_age `alter` INT,
CHANGE person_income jahreseinkommen INT,
CHANGE person_home_ownership wohnsituation VARCHAR(20),
CHANGE person_emp_length beschaeftigungsdauer DOUBLE,
CHANGE loan_intent kreditzweck VARCHAR(30),
CHANGE loan_grade bonitaetsklasse VARCHAR(5),
CHANGE loan_amnt kreditsumme INT,
CHANGE loan_int_rate zinssatz DOUBLE,                        -- DOUBLE steht für Decimal Zahlen
CHANGE loan_status kreditausfall INT,
CHANGE loan_percent_income kreditanteil_einkommen DOUBLE,
CHANGE cb_person_default_on_file zahlungsausfall_historie VARCHAR(5),
CHANGE cb_person_cred_hist_length laenge_kredithistorie INT;

ALTER TABLE credit_risk 
CHANGE `alter` alter_jahr INT;

SELECT DISTINCT laenge_kredithistorie FROM credit_risk;

-- Unbennanten Spalten erfolgreich (Check)?
DESCRIBE credit_risk;                 -- einmal rumgehen und lesen, ob alle Spalten stimmen



-- ====================================================================================================================================

-- I): Explorative Datenanalyse (EDA)

-- 1.1 Wie viele Datensätze (Kreditnehmer) gibt es?
SELECT COUNT(*) AS anzahl_kredite                       -- Zählt alle Zeilen in der Tabelle; Damit prüfen wir, ob der Import korrekt war.
FROM credit_risk;


-- 1.2 Überblick über Spalten
DESCRIBE credit_risk;                 -- Welche Spalten existieren und welche Datentypen sie haben


-- 1.3 Die ersten 10 Fälle anschauen
-- Erste 10 Kreditnehmer anschauen
SELECT *
FROM credit_risk
LIMIT 10;                                         -- LIMIT : beschränkt sich auf die ersten 10 Zeilen des Datensatzes


-- 1.4 Fehlende Werte finden
-- ZWECK: Herausfinden, welche Spalten unvollständige Daten haben
-- Wir prüfen, wo Daten fehlen und wie stark das Problem ist
SELECT 
    COUNT(*) - COUNT(alter_jahr) AS Fehlend_Alter,                                                 -- Gesamtzahl minus vorhandene Werte 
    COUNT(*) - COUNT(jahreseinkommen) AS Fehlend_Einkommen,                                        -- Ergebnis = fehlende Werte
    COUNT(*) - COUNT(wohnsituation) AS Fehlend_Wohnsituation,                  
    COUNT(*) - COUNT(beschaeftigungsdauer) AS Fehlend_Beschaeftigungsdauer,
    COUNT(*) - COUNT(kreditzweck) AS Fehlend_Kredit_Zweck,
    COUNT(*) - COUNT(bonitaetsklasse) AS Fehlend_Bewertung,
    COUNT(*) - COUNT(kreditsumme) AS Fehlend_Kreditsumme,
    COUNT(*) - COUNT(zinssatz) AS Fehlend_Zinssatz,
    COUNT(*) - COUNT(kreditausfall) AS Fehlend_Status,
    COUNT(*) - COUNT(kreditanteil_einkommen) AS Fehlend_Prozent_Einkommen,
    COUNT(*) - COUNT(zahlungsausfall_historie) AS Fehlend_Frueherer_Ausfall,
    COUNT(*) - COUNT(laenge_kredithistorie) AS Fehlend_Kredit_Historie
FROM credit_risk;


-- 1.5 Ausreißer finden (Beschaeftigungsdauer und Zinssatz?)
-- Beschaeftigungsdauer
SELECT 
    ROUND(AVG(Beschaeftigungsdauer), 2) AS Durchschnitt_Beschaeftigungsdauer,                  -- 123 Jahre Beschaeftigungsdauer?
    ROUND(MIN(Beschaeftigungsdauer), 2) AS Minimum_Beschaeftigungsdauer,
    ROUND(MAX(Beschaeftigungsdauer), 2) AS Maximum_Beschaeftigungsdauer,
    ROUND(STDDEV(Beschaeftigungsdauer), 2) AS Standardabweichung_Beschaeftigungsdauer
FROM credit_risk
WHERE Beschaeftigungsdauer IS NOT NULL;


-- Zinssatz
SELECT
	MIN(zinssatz) AS Minimum_zinssatz,
	MAX(zinssatz) AS Maximum_zinssatz,
	ROUND(AVG(zinssatz), 1) AS Durchschnitt_zinssatz,
	ROUND(STDDEV(zinssatz), 1) AS Standardabweichung_zinssatz
FROM credit_risk
WHERE zinssatz IS NOT NULL;


-- Überblick über die wichtigsten Zahlen (gibt noch Aussreißer?)
-- Minimum, Maximum, Durchschnitt, Streuung
-- Finden unrealistische Werte (z. B. Alter 144)
SELECT 
    COUNT(*) AS Gesamt_Kreditnehmer,                                          -- Min, Max helfen Ausreißer zu erkennen
    MIN(alter_jahr) AS Juengster,
    MAX(alter_jahr) AS Aeltester,
    ROUND(AVG(alter_jahr), 1) AS Durchschnitts_Alter_jahr,
	ROUND(STDDEV(alter_jahr), 1) AS Standardabweichung_Alter_jahr,
    MIN(jahreseinkommen) AS Niedrigstes_Einkommen,
    MAX(jahreseinkommen) AS Hoechstes_Einkommen,
    ROUND(AVG(jahreseinkommen), 1) AS Durchschnitts_Einkommen,
    ROUND(STDDEV(jahreseinkommen), 1) AS Standardabweichung_Einkommen,
    MIN(kreditsumme) AS Kleinster_Kredit,
    MAX(kreditsumme) AS Groesster_Kredit,
    ROUND(AVG(kreditsumme), 1) AS Durchschnitts_Kredit,
	ROUND(STDDEV(kreditsumme), 1) AS Standardabweichung_kredit
FROM credit_risk;


-- 1.6 Duplikate suchen?
-- Duplikate suchen
SELECT 
    alter_jahr,
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,
    zinssatz,
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie,
    COUNT(*) AS Anzahl_Vorkommen
FROM credit_risk
GROUP BY 
    alter_jahr,
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,
    zinssatz,
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie
HAVING COUNT(*) > 1
ORDER BY Anzahl_Vorkommen DESC; 


-- Gesamtzahl echte Duplikate
/*
Für jede Gruppe, die mehrfach vorkommt,
zähle nur die extra Kopien
(eine Zeile gilt immer als Original).
*/
SELECT 
    SUM(Anzahl_Vorkommen - 1) AS Gesamt_Duplikate              -- 165 Duplikaten, löschen? 
FROM (
    SELECT 
        COUNT(*) AS Anzahl_Vorkommen
    FROM credit_risk
    GROUP BY 
	alter_jahr,
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,
    zinssatz,
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie
    HAVING COUNT(*) > 1
) AS DuplikatZaehlung;


-- Verdächtige Personen mit mehreren Krediten?
SELECT 
    alter_jahr AS `Alter`,
    jahreseinkommen AS Einkommen,
    wohnsituation AS Wohnsituation,
    COUNT(*) AS Anzahl_Kredite
FROM credit_risk
GROUP BY alter_jahr, jahreseinkommen, Wohnsituation
HAVING COUNT(*) > 2                   -- Mehr als 2 Kredite
ORDER BY Anzahl_Kredite DESC
LIMIT 20;

-- Schauen wir uns zur Kontrole erstmal die 93 Kredite von "22 Jahre, 30k, RENT" an:
SELECT 
    alter_jahr,
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,
    zinssatz,
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie,
    COUNT(*) AS Anzahl_Identisch
FROM credit_risk
WHERE alter_jahr = 22 
  AND jahreseinkommen = 30000 
  AND wohnsituation = 'Miete'
GROUP BY 
    alter_jahr,
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,
    zinssatz,
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie
ORDER BY Anzahl_Identisch DESC;
-- Anzahl_Identisch auf 1 bedeutet, dass es kommt nur einmal vor.alter
-- keine verdächtige Personen
 

-- 1.7 Verteilungen 
-- Wohnsituation
SELECT wohnsituation, COUNT(*) AS anzahl
FROM credit_risk
GROUP BY wohnsituation
ORDER BY anzahl DESC;

-- Kreditzweck
SELECT kreditzweck, COUNT(*) AS anzahl
FROM credit_risk
GROUP BY kreditzweck
ORDER BY anzahl DESC;

-- Bonitätsklasse
SELECT bonitaetsklasse, COUNT(*) AS anzahl
FROM credit_risk
GROUP BY bonitaetsklasse
ORDER BY bonitaetsklasse;

-- Kreditausfall
SELECT
    kreditausfall,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM credit_risk), 2) AS anteil_prozent
FROM credit_risk
GROUP BY kreditausfall;

-- erste einfache Beziehung: Ausfall vs. Bonität
SELECT
    bonitaetsklasse,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY bonitaetsklasse
ORDER BY bonitaetsklasse;



-- =================================================================================================================================

-- Backup Datensatz
CREATE TABLE credit_risk_original AS                                               -- Zweck: Original-Daten sichern, falls etwas schiefgeht
SELECT * FROM credit_risk;                                                         

-- Validierung: Prüfen, ob Backup erfolgreich
SELECT 
    'Backup erstellt' AS Status,
    COUNT(*) AS Anzahl_Zeilen
FROM credit_risk_original;

-- ==================================================================================================================================

-- II): DATEN BEREINIGUNG (Data Cleaning)

-- 2.1 Fehlende Werte behandeln
-- Beschaeftigungsdauer fehlend löschen? 
-- Wir teilen alle Kreditnehmer in zwei Gruppen:

SELECT
    CASE
        WHEN beschaeftigungsdauer IS NULL THEN 'Fehlt'                              -- 1 = Beschäftigungsdauer vorhanden
        ELSE 'Vorhanden'                                                            -- 2 = Beschäftigungsdauer fehlt (NULL)
    END AS beschaeftigungsdauer_status,                                             -- Danach vergleichen wir wichtige Kennzahlen beider Gruppen
    -- Anzahl der Kredite pro Gruppe
    
    COUNT(*) AS anzahl_kredite,
    -- Durchschnittlicher Kreditbetrag  
    
    ROUND(AVG(kreditsumme), 2) AS avg_kreditbetrag,
    -- Durchschnittliches Einkommen
    
    ROUND(AVG(jahreseinkommen), 2) AS avg_einkommen,
    -- Ausfallquote:
    -- loan_status = 1 bedeutet Ausfall
    -- AVG davon ergibt direkt die Prozentquote
    
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent                     -- Kunden ohne Beschäftigungsangabe fallen deutlich häufiger aus (Unbedingt behalten: Risikofaktor)
FROM credit_risk
GROUP BY beschaeftigungsdauer_status;


-- Zinssatz fehlend löschen?
-- Wir teilen alle Kredite in zwei Gruppen:

SELECT
    CASE
        WHEN zinssatz IS NULL THEN 'Fehlt'                                 -- 1 = Zinssatz vorhanden
        ELSE 'Vorhanden'                                                   -- 2 = Zinssatz fehlt (NULL)
    END AS zinssatz_status,                                                -- Anschließend vergleichen wir wichtige Kennzahlen
    -- Anzahl der Kredite pro Gruppe
    COUNT(*) AS anzahl_kredite,
    
    -- Durchschnittlicher Kreditbetrag
    ROUND(AVG(kreditsumme), 2) AS avg_kreditbetrag,

    -- Durchschnittliches Einkommen
    ROUND(AVG(jahreseinkommen), 2) AS avg_einkommen,

    -- Ausfallquote in Prozent
    -- loan_status: 0 = kein Ausfall, 1 = Ausfall
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent

FROM credit_risk
GROUP BY zinssatz_status;                                                        -- Sie betreffen über 3 000 Kredite (Daten behalten: Integrität meines Datensatzes)


-- 2.2 komische Werte behandeln 
-- Ist Alter 144 realistisch?
SELECT
    alter_jahr,                                       -- Zeigt alle Kreditnehmer mit unrealistisch hohem Alter
    COUNT(*) AS anzahl                                -- Hier setzen wir eine fachlich sinnvolle Grenze, z.B. > 100 Jahre
FROM credit_risk
WHERE alter_jahr > 100
GROUP BY alter_jahr
ORDER BY alter_jahr DESC;                              


-- Nur Alter auf Null setzen 
SET SQL_SAFE_UPDATES = 0;

UPDATE credit_risk                                    -- Setzt unrealistische Alterswerte auf NULL
SET alter_jahr = NULL                                 -- Betroffen sind nur 5 Datensätze (< 0,02 %)
WHERE alter_jahr > 100;                               -- Einkommen und wichtige Kenntzahlen bleiben korrekt (Integrität von dem Datensatz priorisieren)

SET SQL_SAFE_UPDATES = 1;


-- 2.3 Warum Duplikate nicht löschen
SELECT
    COUNT(*) AS gesamt_zeilen,                     -- Zählt vollständig identische Datensätze
    COUNT(DISTINCT CONCAT(                         -- Ziel: Nur sichtbar machen, nicht löschen
	alter_jahr,          
    jahreseinkommen,
    wohnsituation,
    beschaeftigungsdauer,
    kreditzweck,
    bonitaetsklasse,
    kreditsumme,                                            -- 4 084 potenzielle Duplikate
    zinssatz,                                               -- 12,5 % des gesamten Datensatzes (Das ist viel: Diese „Duplikate“ sind geschäftsrelevant, nicht vernachlässigbar.)
    kreditausfall,
    kreditanteil_einkommen,
    zahlungsausfall_historie,
    laenge_kredithistorie
    )) AS eindeutige_zeilen
FROM credit_risk;     


-- 2.4 Spalten's Werte auf deutsch übersetzen (Wohnsituation, Kreditzweck, Zahlungsausfall)         
-- Wohnsituation
SET SQL_SAFE_UPDATES = 0;

UPDATE credit_risk
SET wohnsituation = CASE
    WHEN wohnsituation = 'RENT' THEN 'Miete'
    WHEN wohnsituation = 'OWN' THEN 'Eigentum'
    WHEN wohnsituation = 'MORTGAGE' THEN 'Hypothek'
    WHEN wohnsituation = 'OTHER' THEN 'Sonstiges'
    ELSE wohnsituation
END;                                                                  -- Übersetzt die Wohnsituation ins Deutsche für Einförmichkeit der Daten

SET SQL_SAFE_UPDATES = 1;

-- kreditzweck
SET SQL_SAFE_UPDATES = 0;

UPDATE credit_risk
SET kreditzweck = CASE
    WHEN kreditzweck = 'PERSONAL' THEN 'Privat'
    WHEN kreditzweck = 'EDUCATION' THEN 'Ausbildung'
    WHEN kreditzweck = 'MEDICAL' THEN 'Medizinisch'
    WHEN kreditzweck = 'VENTURE' THEN 'Unternehmung'
    WHEN kreditzweck = 'HOMEIMPROVEMENT' THEN 'Hausverbesserung'
    WHEN kreditzweck = 'DEBTCONSOLIDATION' THEN 'Schuldenkonsolidierung'
    ELSE kreditzweck
END;

SET SQL_SAFE_UPDATES = 1;

-- zahlungsausfall_historie übersetzen
SET SQL_SAFE_UPDATES = 0;

UPDATE credit_risk
SET zahlungsausfall_historie = CASE
    WHEN zahlungsausfall_historie = 'Y' THEN 'Ja'
    WHEN zahlungsausfall_historie = 'N' THEN 'Nein'
    ELSE zahlungsausfall_historie
END;                                                               -- Übersetzt Zahlungsausfall-Historie in Ja / Nein

SET SQL_SAFE_UPDATES = 1;

-- Kontrolle
SELECT DISTINCT wohnsituation FROM credit_risk;
SELECT DISTINCT kreditzweck FROM credit_risk;
SELECT DISTINCT zahlungsausfall_historie FROM credit_risk;


-- =========================================================================================================================================

-- III): FEATURE ENGENEERING

-- 3.1 Aufbau der Risiko-Klassifikation
/*Risiko-Klassifikation für jeden Kreditnehmer
-- Ziel: Einteilung in Niedriges, Mittleres und Hohes Risiko
-- Die Logik basiert auf:
-- 1) Bonitätsklasse
-- 2) Zahlungsausfall-Historie
-- 3) Kreditbelastung im Verhältnis zum Einkommen
*/

-- 	3.1.1 Fachliche Grundidee (Klassifikation)
SELECT                                                                   -- Alle bestehenden Spalten anzeigen
    *,   
	CASE
        -- HOHES RISIKO
        WHEN bonitaetsklasse IN ('E', 'F', 'G')                                    -- sehr schlechte Bonität (E, F, G)
             OR zahlungsausfall_historie = 'Ja'                                    -- früherer Zahlungsausfall
             OR kreditanteil_einkommen > 0.40                                      -- extrem hohe Kreditbelastung (> 40 % des Einkommens) 
        THEN 'Hohes Risiko'                                                        

        -- MITTLERES RISIKO
        WHEN bonitaetsklasse IN ('C', 'D')                                         -- Erhöhtes Risiko, aber nicht kritisch:  mittlere Bonitätsklasse (C, D)
             OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40                       -- Kreditbelastung zwischen 25 % und 40 %
        THEN 'Mittleres Risiko'
	
        -- NIEDRIGES RISIKO
        ELSE 'Niedriges Risiko'                                                    -- Alles andere → niedriges Risiko
    END AS risiko_kategorie
FROM credit_risk;                                      


-- 	3.1.2 Ausfallquote nach Bonitätsklasse berechnen (Klassifikationsgrad fachlich begründen)
SELECT 
    bonitaetsklasse,
    COUNT(*) AS anzahl_kredite,
    SUM(kreditausfall) AS anzahl_ausfaelle,
    ROUND(SUM(kreditausfall ) * 100.0 / COUNT(*), 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY bonitaetsklasse 
ORDER BY bonitaetsklasse DESC;
/* 
-- Prüft den Zusammenhang zwischen Bonitätsklasse und Ausfallquote
-- Ziel: Validierung, dass E, F, G tatsächlich risikoreicher sind
-- Die Ausfallquote steigt stark mit schlechterer Bonitätsklasse an
*/


-- ==========================================================================================================================================

-- IV): ANALYSE UND INTERPRETATION

-- 4.1 Kredit gleich intensiv überwachen?
-- 	4.1.1 Wie viele Kunden sind in welcher Risikogruppe? (Risikogruppen quantifizieren) 
-- Nicht alle Kredite sind gleich riskant – Überwachung kann differenziert werden
SELECT
    risiko_kategorie,                                                                          
    COUNT(*) AS anzahl_kredite,                                                                
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM credit_risk) * 100, 2) AS anteil_prozent
FROM (
    -- Unterabfrage: Risiko-Klassifikation
    SELECT
        CASE
            WHEN bonitaetsklasse IN ('E', 'F', 'G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C', 'D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie
    FROM credit_risk
) t                                                                   
GROUP BY risiko_kategorie                                             
ORDER BY anteil_prozent DESC;
/*
wichtigste Überwachunsfaktoren : bonitaetsklasse, kreditanteil_einkommen, zahlungsausfall_historie (einfache Interpretation)
Die Mehrheit der Kreditnehmer befindet sich in der Niedrigrisikogruppe, während Mittel- und Hochrisikokunden einen kleineren, aber relevanten Anteil ausmachen.
Die Verteilung ist ausgewogen und weist weder auf eine zu konservative noch auf eine zu lockere Kreditvergabe hin.
Damit eignet sich die Risikoklassifikation gut als Grundlage für eine risikobasierte Kreditüberwachung.
*/

-- 	4.1.2 Überwachungslogik definieren (Model)
SELECT
    *,
    CASE
        WHEN risiko_kategorie = 'Hohes Risiko' THEN 'Intensive Überwachung'                -- Verknüpft jede Risikokategorie mit einer Überwachungsstufe
        WHEN risiko_kategorie = 'Mittleres Risiko' THEN 'Standard-Überwachung'             -- Ergebnis: konkrete Handlungsanweisung für das Kreditmanagement
        ELSE 'Reduzierte Überwachung'
    END AS ueberwachungsstufe
FROM (
    -- Unterabfrage: Risikoklassifikation
    SELECT
        *,
        CASE
            WHEN bonitaetsklasse IN ('E', 'F', 'G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'

            WHEN bonitaetsklasse IN ('C', 'D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'

            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie
    FROM credit_risk
) t;
/*
Die Überwachungslogik leitet aus der Risikokategorie direkt eine passende Überwachungsintensität ab.
Risikoreiche Kredite werden gezielt intensiver überwacht, während risikoarme Kredite mit reduziertem Aufwand betreut werden.
*/

-- 	4.1.3 Ausfallquoten nach Wohnsituation
SELECT wohnsituation, 
COUNT(*) AS anzahl_kredite, 
SUM(kreditausfall ) AS anzahl_ausfaelle, 
ROUND(SUM(kreditausfall ) * 100.0 / COUNT(*), 2) AS ausfallquote_prozent 
FROM credit_risk 
GROUP BY wohnsituation 
ORDER BY ausfallquote_prozent DESC;

-- 	4.1.4 Ausfallquoten nach Kreditzweck
-- Hilft bei der Priorisierung der Kreditüberwachung
SELECT
    kreditzweck,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall ) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY kreditzweck
ORDER BY ausfallquote_prozent DESC;
/*Die Ausfallquoten unterscheiden sich deutlich je nach Kreditzweck.
Einzelne Verwendungszwecke weisen ein erhöhtes Ausfallrisiko auf und eignen sich daher besonders für eine priorisierte Kreditüberwachung.
*/


-- 	4.1.5 Ausfallquote nach Risikokategorie validieren
-- Prüft, ob die Risikokategorien tatsächlich unterschiedliche Ausfallquoten haben
-- Validierung der Risiko-Klassifikation
SELECT
    risiko_kategorie,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall ) * 100, 2) AS ausfallquote_prozent
FROM (
    SELECT
        CASE
            WHEN bonitaetsklasse IN ('E','F','G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C','D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie,
        kreditausfall 
    FROM credit_risk
) t
GROUP BY risiko_kategorie
ORDER BY ausfallquote_prozent DESC;
/*
Die Ausfallquote steigt deutlich von der Niedrig- über die Mittel- zur Hochrisikogruppe an.
Damit bestätigt diese Analyse die Trennschärfe und fachliche Validität der entwickelten Risikoklassifikation.
*/

-- 	4.1.6 Kredit-Einkommens-Verhältnis nach Ausfallquote
SELECT 
    CASE 
        WHEN  kreditanteil_einkommen < 0.1 THEN '1. Unter 10%'
        WHEN  kreditanteil_einkommen BETWEEN 0.1 AND 0.2 THEN '2. 10-20%'
        WHEN  kreditanteil_einkommen BETWEEN 0.2 AND 0.3 THEN '3. 20-30%'
        WHEN  kreditanteil_einkommen BETWEEN 0.3 AND 0.4 THEN '4. 30-40%'
        WHEN  kreditanteil_einkommen BETWEEN 0.4 AND 0.5 THEN '5. 40-50%'
        ELSE '6. Über 50%'
    END AS kredit_einkommens_verhaeltnis,
    COUNT(*) AS anzahl_kredite,
    SUM(kreditausfall) AS anzahl_ausfaelle,
    ROUND(SUM(kreditausfall ) * 100.0 / COUNT(*), 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY 
    CASE 
        WHEN kreditanteil_einkommen < 0.1 THEN '1. Unter 10%'
        WHEN kreditanteil_einkommen BETWEEN 0.1 AND 0.2 THEN '2. 10-20%'
        WHEN kreditanteil_einkommen BETWEEN 0.2 AND 0.3 THEN '3. 20-30%'
        WHEN kreditanteil_einkommen BETWEEN 0.3 AND 0.4 THEN '4. 30-40%'
        WHEN kreditanteil_einkommen BETWEEN 0.4 AND 0.5 THEN '5. 40-50%'
        ELSE '6. Über 50%'
    END
ORDER BY ausfallquote_prozent DESC;
/*
Solange der Kredit weniger als ein Viertel des Einkommens kostet, klappt die Rückzahlung meist.
Sobald er aber ein Drittel oder mehr vom Einkommen frisst, geht es sehr häufig schief.
*/


-- 	4.1.7 Ausfallquote nach Beschäftigungsdauer
-- Ziel: prüfen, ob längere Beschäftigung mit geringerem Risiko einhergeht
SELECT
    CASE
        WHEN beschaeftigungsdauer < 1 THEN 'Unter 1 Jahr'
        WHEN beschaeftigungsdauer BETWEEN 1 AND 3 THEN '1–3 Jahre'
        WHEN beschaeftigungsdauer BETWEEN 4 AND 7 THEN '4–7 Jahre'
        ELSE 'Über 7 Jahre'
    END AS beschaeftigungsgruppe,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
WHERE beschaeftigungsdauer IS NOT NULL
GROUP BY
    CASE
        WHEN beschaeftigungsdauer < 1 THEN 'Unter 1 Jahr'
        WHEN beschaeftigungsdauer BETWEEN 1 AND 3 THEN '1–3 Jahre'
        WHEN beschaeftigungsdauer BETWEEN 4 AND 7 THEN '4–7 Jahre'
        ELSE 'Über 7 Jahre'
    END
ORDER BY ausfallquote_prozent DESC;
/*
Wer erst kurz im Job ist, hat häufiger Probleme, einen Kredit zurückzuzahlen.
Wer lange arbeitet, ist meist zuverlässiger – aber das allein entscheidet nicht.
*/

-- 	4.1.8 Berechnung altersbasierte Risiko-Kategorie
--  Ausfallquote nach Altersgruppen
SELECT
    CASE
        WHEN alter_jahr < 25 THEN 'Unter 25'
        WHEN alter_jahr BETWEEN 25 AND 35 THEN '25–35'
        WHEN alter_jahr BETWEEN 36 AND 55 THEN '36–55'
        ELSE 'Über 55'
    END AS altersgruppe,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
WHERE alter_jahr IS NOT NULL
GROUP BY
    CASE
        WHEN alter_jahr < 25 THEN 'Unter 25'
        WHEN alter_jahr BETWEEN 25 AND 35 THEN '25–35'
        WHEN alter_jahr BETWEEN 36 AND 55 THEN '36–55'
        ELSE 'Über 55'
    END
ORDER BY ausfallquote_prozent DESC;
/*
Ob jemand jung oder alt ist, macht kaum einen Unterschied.
Entscheidend ist, wie gut jemand bisher gezahlt hat und wie stark der Kredit das Einkommen belastet.
*/


-- 	4.1.9 Kreditsumme nach Ausfallstatus
-- Ziel: Wie viel Geld steckt in ausgefallenen vs. nicht ausgefallenen Krediten?
SELECT
    risiko_kategorie,
    COUNT(*) AS anzahl_kredite,
    ROUND(SUM(kreditsumme), 0) AS gesamt_kreditsumme,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote
FROM (
    SELECT
        kreditsumme,
        kreditausfall,
        CASE
            WHEN bonitaetsklasse IN ('E','F','G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C','D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie
    FROM credit_risk
) t
GROUP BY risiko_kategorie
ORDER BY ausfallquote DESC;


-- 	4.1.10 Wie viele Kredite müssen intensiv überwacht werden?
SELECT
    ueberwachungsstufe,                                                                       
    COUNT(*) AS anzahl_kredite,                                                                     -- Zeigt, wie viele Kredite je Überwachungsstufe existieren
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM credit_risk) * 100, 2) AS anteil_prozent                 -- Wichtig für Kosten- und Ressourcenplanung
    
FROM (
    SELECT
        CASE
            WHEN risiko_kategorie = 'Hohes Risiko' THEN 'Intensive Überwachung'
            WHEN risiko_kategorie = 'Mittleres Risiko' THEN 'Standard-Überwachung'
            ELSE 'Reduzierte Überwachung'
        END AS ueberwachungsstufe
    FROM (
        -- Risikoermittlung
        SELECT
            CASE
                WHEN bonitaetsklasse IN ('E', 'F', 'G')
                     OR zahlungsausfall_historie = 'Ja'
                     OR kreditanteil_einkommen > 0.40
                THEN 'Hohes Risiko'
                WHEN bonitaetsklasse IN ('C', 'D')
                     OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
                THEN 'Mittleres Risiko'
                ELSE 'Niedriges Risiko'
            END AS risiko_kategorie
        FROM credit_risk
    ) r
) u
GROUP BY ueberwachungsstufe
ORDER BY anteil_prozent DESC;
/*
Die Quantifizierung der Überwachungsstufen zeigt, dass nur ein Teil des Kreditportfolios eine intensive Überwachung erfordert.
Der Großteil der Kredite kann mit Standard- oder reduzierter Überwachung betreut werden, wodurch Überwachungskosten gezielt gesenkt 
und Ressourcen effizient eingesetzt werden können.
*/


-- 4.2 Sind Kredite falsch bepreist oder falsch vergeben worden?
-- 	4.2.1 Niedriges Einkommen + hoher Kredit (Vergabe)
-- Findet Kredite mit auffälligem Verhältnis:
-- niedriges Einkommen, aber hohe Kreditsumme
-- Diese Kredite könnten schwer rückzahlbar sein
SELECT
    jahreseinkommen AS einkommen,                           
    kreditsumme,                                            
    kreditanteil_einkommen,                                 
    bonitaetsklasse,
    zinssatz  ,
    kreditausfall
FROM credit_risk
WHERE jahreseinkommen < 30000                          -- niedriges Einkommen
  AND kreditsumme  > 20000                             -- hohe Kreditsumme
ORDER BY kreditsumme  DESC;
/*
Diese Analyse identifiziert Kredite, bei denen die Kreditsumme in keinem angemessenen Verhältnis zum Einkommen des Kreditnehmers steht.
Solche Konstellationen sind mit einem erhöhten Rückzahlungs- und Ausfallrisiko verbunden 
und deuten auf mögliche Abweichungen von internen Vergaberichtlinien hin.
*/


-- 	4.2.2 Schlechte Bonität + hohe Kreditsumme 
SELECT
    bonitaetsklasse,                                -- Identifiziert Kredite mit schlechter Bonität
    kreditsumme,                                    -- aber gleichzeitig sehr hoher Kreditsumme
    jahreseinkommen,
    zinssatz,
    kreditausfall
FROM credit_risk
WHERE bonitaetsklasse IN ('E','F','G')   -- schlechte Bonität
  AND kreditsumme  > 25000                  -- sehr hohe Kredite
ORDER BY kreditsumme  DESC;
/*
Diese Analyse zeigt Kredite mit sehr schlechter Bonität, denen dennoch hohe Kreditsummen gewährt wurden.
Solche Vergaben stehen im Widerspruch zu einer risikobewussten Kreditvergabe und bergen ein erhöhtes Ausfall- 
und Verlustpotenzial für die Bank.
*/

-- 	4.2.3 Anzahl auffälliger Kredite je Kategorie 
SELECT
    'Niedriges Einkommen + Hoher Kredit' AS auffaelligkeit,                 -- Zählt, wie viele Kredite in jeder Auffälligkeitsklasse existieren
    COUNT(*) AS anzahl_kredite                                              -- Liefert eine kompakte Management-Übersicht
FROM credit_risk
WHERE jahreseinkommen  < 30000
  AND kreditsumme  > 20000

UNION ALL

SELECT
    'Hohes Risiko + Niedriger Zinssatz',
    COUNT(*)
FROM credit_risk
WHERE (bonitaetsklasse IN ('E','F','G')
       OR zahlungsausfall_historie = 'Ja'
       OR kreditanteil_einkommen > 0.40)
  AND zinssatz  < 10

UNION ALL

SELECT
    'Schlechte Bonität + Hoher Kredit',
    COUNT(*)
FROM credit_risk
WHERE bonitaetsklasse IN ('E','F','G')
  AND kreditsumme  > 25000;
/*
Die aggregierte Übersicht zeigt, dass Auffälligkeiten in mehreren Bereichen der Kreditvergabe auftreten.
Insbesondere betreffen sie sowohl die Höhe der Kredite als auch eine nicht risikosensitive Zinsgestaltung.
Dies bestätigt, dass es sich nicht um Einzelfälle, sondern um systematische Schwachstellen im Kreditvergabeprozess handelt.
*/

-- 	4.2.4 Hohes Risiko + niedriger Zinssatz (Pricing-Problem)
SELECT
    bonitaetsklasse,                                         -- Prüft, ob riskante Kreditnehmer ungewöhnlich niedrige Zinssätze erhalten
    zahlungsausfall_historie,                                -- Das deutet auf fehlende Risikobepreisung hin
    kreditanteil_einkommen,
    zinssatz,
    kreditsumme,
    kreditausfall
FROM credit_risk
WHERE
    -- Kriterien für hohes Risiko
    (bonitaetsklasse IN ('E','F','G')
     OR zahlungsausfall_historie = 'Ja'
     OR kreditanteil_einkommen > 0.40)
AND zinssatz  < 10              -- ungewöhnlich niedriger Zinssatz
ORDER BY zinssatz  ASC;
/*
Hochriskante Kreditnehmer erhalten teilweise ungewöhnlich niedrige Zinssätze.
Dies weist auf eine unzureichend risikosensitive Preisgestaltung hin und erhöht das wirtschaftliche Risiko für die Bank.
*/


-- 4.3 Weietere Analyse

-- 	4.3.1 Zinssätze nach Risiko vergleichen (Pricing-Check)
-- Prüft, ob das Pricing risikosensitiv ist
-- Erwartung: Hohes Risiko = höherer Zinssatz
SELECT
    risiko_kategorie,
    ROUND(AVG(zinssatz ), 2) AS durchschnittlicher_zinssatz
FROM (
    SELECT
        CASE
            WHEN bonitaetsklasse IN ('E','F','G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C','D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie,
        zinssatz 
    FROM credit_risk
) t
GROUP BY risiko_kategorie
ORDER BY durchschnittlicher_zinssatz DESC;
/*
Die durchschnittlichen Zinssätze unterscheiden sich nur begrenzt zwischen den Risikokategorien.
Dies deutet darauf hin, dass das Kredit-Pricing nicht konsequent an das tatsächliche Risikoprofil der Kreditnehmer angepasst ist.
*/


-- 	4.3.2 Risiko × Kredithöhe (Verlustpotenzial)
-- Kombiniert Risiko und Kredithöhe
-- Ziel: Identifikation von hohem Verlustpotenzial
SELECT
    risiko_kategorie,
    ROUND(AVG(kreditsumme ), 2) AS durchschnittliche_kreditsumme,
    ROUND(SUM(kreditsumme ), 0) AS gesamtvolumen
FROM (
    SELECT
        CASE
            WHEN bonitaetsklasse IN ('E','F','G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C','D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie,
        kreditsumme 
    FROM credit_risk
) t
GROUP BY risiko_kategorie
ORDER BY gesamtvolumen DESC;
/*
Hochrisikokredite vereinen ein hohes Ausfallrisiko mit einem erheblichen Kreditvolumen.
Damit stellen sie das größte potenzielle Verlustpotenzial für die Bank dar und sollten vorrangig überwacht werden.
*/


-- 	4.3.3 Zahlen Menschen ihren Kredit häufiger nicht zurück?
SELECT
    zahlungsausfall_historie,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY zahlungsausfall_historie;
/*
Wer früher schon Schulden nicht zurückgezahlt hat, fällt bei neuen Krediten mehr als doppelt so häufig wieder aus.
*/

-- 	4.3.4 Prüft, wie sich die Ausfallquote bei steigender Kreditbelastung verändert.
-- Kreditanteil am Einkommen
SELECT
    CASE
        WHEN kreditanteil_einkommen < 0.25 THEN 'Niedrige Belastung (<25%)'
        WHEN kreditanteil_einkommen BETWEEN 0.25 AND 0.40 THEN 'Mittlere Belastung (25–40%)'
        ELSE 'Hohe Belastung (>40%)'
    END AS belastungsklasse,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY belastungsklasse
ORDER BY ausfallquote_prozent DESC;
/* 
Wenn mehr als 40 % des Einkommens für den Kredit draufgehen, fallen fast drei von vier Krediten aus.
*/


-- 	4.3.4 Zahlungsausfall-Historie
-- Frühere Ausfälle = starkes Warnsignal
SELECT
    zahlungsausfall_historie,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent
FROM credit_risk
GROUP BY zahlungsausfall_historie;


-- 4.3.5  Verlust in einem Jahr einschätzen
SELECT
    risiko_kategorie,
    ROUND(SUM(kreditsumme), 0) AS gesamt_kreditvolumen,
    ROUND(AVG(kreditausfall) * 100, 2) AS ausfallquote_prozent,
    50 AS verlustquote_prozent,
    
    -- Erwarteter Jahresverlust
    ROUND(
        SUM(kreditsumme)
        * AVG(kreditausfall)
        * 0.50
    , 0) AS erwarteter_jahresverlust
FROM (
    SELECT
        kreditsumme,
        kreditausfall,
        CASE
            WHEN bonitaetsklasse IN ('E','F','G')
                 OR zahlungsausfall_historie = 'Ja'
                 OR kreditanteil_einkommen > 0.40
            THEN 'Hohes Risiko'
            WHEN bonitaetsklasse IN ('C','D')
                 OR kreditanteil_einkommen BETWEEN 0.25 AND 0.40
            THEN 'Mittleres Risiko'
            ELSE 'Niedriges Risiko'
        END AS risiko_kategorie
    FROM credit_risk
) t
GROUP BY risiko_kategorie
ORDER BY erwarteter_jahresverlust DESC;
