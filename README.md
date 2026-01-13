# Smart Mind Map

> Transformez vos PDF en cartes mentales interactives grâce à l'IA Générative locale.

## 📖 À propos
Smart Mind Map est une application innovante qui aide les étudiants et professionnels à synthétiser rapidement de grands volumes d'informations. En combinant la puissance de l'analyse sémantique et la flexibilité du mobile, elle génère automatiquement des structures de connaissances navigables à partir de simples fichiers PDF.

## 🚀 Fonctionnalités Clés
* **Ingestion de Documents :** Support complet des fichiers PDF de cours.
* **Traitement NLP & RAG :** Nettoyage sémantique et filtrage des concepts pertinents via recherche vectorielle.
* **IA Locale (Privacy-First) :** Utilisation d'un LLM local pour la génération des nœuds sans fuite de données.
* **Visualisation Interactive :** Interface Flutter fluide permettant de zoomer, explorer et modifier les cartes mentales ("Deep Dive").

## 🛠 Stack Technique
* **Mobile :** Flutter (Dart)
* **Backend & AI :** Python
* **NLP & Search :** Spacy, SentenceTransformers (RAG)
* **LLM :** Ollama / Llama 3 (Local Inference)

## 🏗 Architecture
Le projet suit une approche hybride :
1.  **Extraction :** Le PDF est parsé et nettoyé.
2.  **Vectorisation :** Les segments de texte sont convertis en vecteurs pour le filtrage RAG.
3.  **Génération :** Le LLM local structure les données en format JSON hiérarchique.
4.  **Rendu :** L'application Flutter dessine dynamiquement l'arbre de connaissances.


