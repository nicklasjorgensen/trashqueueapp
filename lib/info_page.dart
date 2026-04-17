import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Velkommen til TrashQueue Player App!\n\n'
        'Appen som du skal bruge til at holde styr på dine point og købe tjenester i butikken :O\n\n'
        '\n\n'
        'Første skridt:\n\n'
        'Som det allerførste skal du indtaste dit cardID, som står på dit kort. Det er vigtigt, at det er præcis det samme, da det bruges til at identificere dig i systemet.\n\n'
        'Når du har indtastet dit cardID, kan du vælge et navn. Det er det navn, der vil blive vist på leaderboardet\n\n'
        '(Du kan altid ændre dit navn senere hvis du føler for det)\n\n'
        '\n\n'
        'Hvordan fungerer det så?\n\n'
        'Når du har scannet dit kort på flaskeautomaten kan du derefter putte dit pant i\n\n'
        'Du vil derefter kunne se dine point blive opdateret i appen!\n\n'
        'Du kan bruge dine point i butikken til at købe forskellige tjenester, som f.eks. at spille en bestemt sang\n\n'
        '\n\n'
        'Lige nu optjener du 1 point for hver flaske du panter\n\n'
        '\n\n'
        '\n\n'
        'Hvis du har spørgsmål eller brug for hjælp, så tøv ikke med at kontakte os!\n\n'
        'Du kan finde os i chomsky eller spørge efter Jens på åboulevarden\n\n'
        ,
        textAlign: TextAlign.left,
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}