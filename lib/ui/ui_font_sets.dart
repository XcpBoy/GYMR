import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Maps a UiTokens.fontSetId string to the 3 GoogleFonts families a preset
/// actually uses. Kept as 3 roles (not 1 font) because LabStyles.mono() is
/// the workhorse used for ~90% of the app's visible text (not just code/
/// numbers) - a literal handwritten or heavily-rounded font there would be
/// illegible for dense data screens, so "primary" is deliberately chosen to
/// stay reasonably readable even in the warmer/handwritten sets, while
/// headline gets the more expressive pick.
class UiFontSet {
  final String id;
  final String label;
  final TextStyle Function({required double fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing}) headline;
  final TextStyle Function({required double fontSize, FontWeight? fontWeight, Color? color}) body;
  final TextStyle Function({required double fontSize, FontWeight? fontWeight, Color? color, TextDecoration? decoration}) primary;

  const UiFontSet({
    required this.id,
    required this.label,
    required this.headline,
    required this.body,
    required this.primary,
  });
}

// 10 selectable font sets: 5 lean technical/monospace (matching the app's
// current default aesthetic), 5 lean warmer/more approachable - per the
// user's "que no todas sean tan roboticas" request.
final Map<String, UiFontSet> kUiFontSets = {
  'jetbrains_mono': UiFontSet(
    id: 'jetbrains_mono',
    label: 'JETBRAINS MONO',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing ?? -0.5),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.jetBrainsMono(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'ibm_plex': UiFontSet(
    id: 'ibm_plex',
    label: 'IBM PLEX',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.ibmPlexMono(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.ibmPlexSans(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.ibmPlexMono(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'roboto_mono': UiFontSet(
    id: 'roboto_mono',
    label: 'ROBOTO MONO',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.robotoMono(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.robotoMono(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'space_mono': UiFontSet(
    id: 'space_mono',
    label: 'SPACE MONO',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.spaceMono(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.spaceMono(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'source_code': UiFontSet(
    id: 'source_code',
    label: 'SOURCE CODE PRO',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.sourceCodePro(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.sourceCodePro(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'nunito': UiFontSet(
    id: 'nunito',
    label: 'NUNITO',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.nunito(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.w800, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'quicksand': UiFontSet(
    id: 'quicksand',
    label: 'QUICKSAND',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.quicksand(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.karla(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.quicksand(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'karla': UiFontSet(
    id: 'karla',
    label: 'KARLA',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.karla(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.karla(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.karla(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  'poppins': UiFontSet(
    id: 'poppins',
    label: 'POPPINS',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.poppins(
        fontSize: fontSize, fontWeight: fontWeight ?? FontWeight.w600, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
  // Caveat (handwritten) is reserved for headline only - using it for dense
  // body/data text would be illegible, so body/primary fall back to Karla,
  // a plain and very readable humanist sans.
  'caveat': UiFontSet(
    id: 'caveat',
    label: 'CAVEAT (HANDWRITTEN)',
    headline: ({required fontSize, fontWeight, color, letterSpacing}) => GoogleFonts.caveat(
        fontSize: fontSize * 1.15, fontWeight: fontWeight ?? FontWeight.bold, color: color, letterSpacing: letterSpacing),
    body: ({required fontSize, fontWeight, color}) => GoogleFonts.karla(fontSize: fontSize, fontWeight: fontWeight, color: color),
    primary: ({required fontSize, fontWeight, color, decoration}) =>
        GoogleFonts.karla(fontSize: fontSize, fontWeight: fontWeight, color: color, decoration: decoration),
  ),
};

UiFontSet uiFontSetOf(String id) => kUiFontSets[id] ?? kUiFontSets['jetbrains_mono']!;
