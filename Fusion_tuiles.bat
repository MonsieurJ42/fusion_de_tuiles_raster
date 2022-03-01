:: ------------------------------------------------------------------------------------------------
:: ---- Fusionneur de Tuiles
:: ---- auteur : J. Ollier - EVS-ISTHME - CNRS UMR 5600
:: ------------------------------------------------------------------------------------------------
:: Header classique
:: Ce script va décompréser, puis fusionner des données ASCII Tuilé. Il propose ensuite de réaliser un ressampling, et peut découper les données selon une emprise
@echo off
:::: Passage du retour du terminal en UTF-8
chcp 65001
cls
:: ------------------------------------------------------------------------------------------------
set nom=Fusion de tuiles
set titre=%nom%
title %titre%

:: Chemin absolue vers les ASCII
set /p input=Chemin absolue du fichier zip ou des tuiles ASCII ? 

:: Chemin absolue vers l'emplacement du traitement
set /p outpout=Chemin absolue du dossier où seront déposer les fichiers finaux et de traitement ? 

:: Nommage des fichier
set /p nom=Nom à donner aux fichiers finaux ? 

:: Demande découpage
:deman_dcp
set /p dem_dcp=Faut-il decouper ? (o/n)
if "%dem_dcp%" == "o" goto dem_emprise
if "%dem_dcp%" == "n" goto suite1
echo "La réponse n'est pas valide !"
goto deman_dcp
:dem_emprise
:: Chemin absolue vers le fichier zip du RGE
set /p cutline=Fichier shape ou gpks de l'emprise de découpe (appuyer seulement sur Entree si il n'y en a pas) ?
:suite1

:: Demande rééchantillonage
:deman_resp
set /p dem_rsp=Faut-il resampler ? (o/n)
if "%dem_rsp%" == "o" goto dem_resp_size
if "%dem_rsp%" == "n" goto suite2
echo "La réponse n'est pas valide !"
goto deman_resp
:dem_resp_size
set /p res=Taille de la cellule souhaitez en mètres ?
:suite2

:: Demande lambert
:deman_lamb
set /p dem_lamb=Le fichier est il en lambert 93 ? (o/n)
if "%dem_lamb%" == "o" goto lamb_bon
if "%dem_lamb%" == "n" goto lamb_pas_bon
echo "La réponse n'est pas valide !"
goto deman_lamb
:: Si non lambert demandee du code de projection
:lamb_pas_bon
set /p proj=Qu'elle est le code EPSG de la projection ?
goto suite
:: Si en lambert 93
:lamb_bon
set proj=2154

:: Zip ou ASCII brut
:deman_zip
set /p dem_zip=Zip ou ASCII ? (zip/ascii)
if "%dem_zip%" == "zip" goto dz_zip
if "%dem_zip%" == "ascii" goto dz_ascii
echo "La réponse n'est pas valide !"
goto deman_zip
:: Dezipage avec 7z
:dz_zip
mkdir %input%\fichier\
7z e -aou %input%\*.7z -o%input%\fichier\
set input_asc=%input%\fichier\
goto deman_dal
:: Emplacement des  ASCII
:dz_ascii
set input_asc=%input%
goto deman_dal

:: Ajout de dalle
:deman_dal
set /p dem_dal=Faut-il ajouter des dalles d'un autre envoie ? (o/n)
if "%dem_dal%" == "o" goto ajout_dal
if "%dem_dal%" == "n" goto contin_ss_dal
echo "La réponse n'est pas valide !"
goto deman_dal
:ajout_dal
echo Merci de glisser les fichier .asc à ajouter dans le dossier fichier
PAUSE
:contin_ss_dal

:: List file
dir /b /s %input_asc%\*.asc > %outpout%\asc_list.txt

:: Fusion GDAL dans un VRT
gdalbuildvrt -a_srs EPSG:%proj% -input_file_list %outpout%\asc_list.txt  %outpout%\tmp.vrt

:: Transformation du VRT en fichier Tif
gdal_translate -a_srs EPSG:%proj% -of GTiff %outpout%\tmp.vrt %outpout%\%nom%.tif

:: Lancement du resampling
:deman_resp
if "%dem_rsp%" == "o" goto rsp
if "%dem_rsp%" == "n" goto deman_dcp
:rsp
saga_cmd grid_tools 0 -INPUT=%outpout%\%nom%.tif -TARGET_DEFINITION=0 -TARGET_USER_SIZE=%res% -OUTPUT=%outpout%\%nom%_%res%m.tif -SCALE_UP=2

:: Découpage selon la ligne de découp
if "%dem_dcp%" == "o" goto dcp
if "%dem_dcp%" == "n" goto fin
:dcp
if "%dem_rsp%" == "o" gdalwarp -s_srs EPSG:%proj% -t_srs EPSG:%proj% -of GTiff -cutline %cutline% -crop_to_cutline -dstnodata -9999.0 %outpout%\%nom%_%res%m.tif %input%\%nom%_%res%m_cut.tif
if "%dem_rsp%" == "n" gdalwarp -s_srs EPSG:%proj% -t_srs EPSG:%proj% -of GTiff -cutline %cutline% -crop_to_cutline -dstnodata -9999.0 %outpout%\%nom%_%.tif %input%\%nom%_cut.tif

:: Fin
:fin
echo Les fichiers sont déposer dans le dosser %output%\
PAUSE