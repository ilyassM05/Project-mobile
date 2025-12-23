# Cahier des Charges — Plateforme Mobile d’Apprentissage Décentralisée

## 1. Présentation Générale du Projet

Le projet consiste à développer une **application mobile d’apprentissage** utilisant :

- **Flutter** pour l’interface et la logique client.
- **Firebase** pour l’authentification, la gestion des données et le stockage.
- **Blockchain (Solidity + testnet Ethereum)** pour l’achat de cours en ETH et la certification NFT.
- **Un modèle léger de recommandation (Deep Learning)** pour proposer aux étudiants les cours les plus pertinents.

L’objectif est d’offrir une plateforme éducative moderne, transparente et sécurisée tout en intégrant des technologies avancées.

---

## 2. Objectifs Fonctionnels

### 2.1. Objectifs Pédagogiques

- Démocratiser l’accès à une éducation numérique de qualité.
- Assurer la transparence dans les transactions éducatives.
- Certifier les compétences via des certificats immuables.

### 2.2. Objectifs Techniques

- Proposer une application mobile simple, stable et intuitive.
- Intégrer un système de paiement basé sur la blockchain pour l’achat sécurisé de cours.
- Mettre en place un mécanisme de certification NFT.
- Fournir un système de recommandation personnalisé.

---

## 3. Fonctionnalités de l’Application

### 3.1. Authentification Utilisateur

- Inscription via email/mot de passe (Firebase Auth).
- Connexion/ déconnexion.
- Rôles : Étudiant / Formateur.

### 3.2. Gestion des Cours

- Consultation de la liste des cours.
- Affichage des détails (titre, description, formateur, prix, tags).
- Lecture des vidéos du cours via Firebase Storage.
- Suivi de la progression.

### 3.3. Achat de Cours via Blockchain

- Affichage du prix du cours en ETH.
- Interaction avec un smart contract Solidity via `web3dart`.
- Transaction sur un testnet.
- Historique des achats (Firestore + blockchain logs).

### 3.4. Certification Blockchain (NFT)

- Mint d’un certificat NFT ERC-721 après validation du cours.
- Stockage des métadonnées du certificat sur IPFS.
- Vérification de la propriété du certificat par l’adresse du wallet.
- Affichage du certificat dans l’application.


## 4. Architecture Technique

### 4.1. Architecture Globale

- **Frontend :** Flutter.
- **Backend :** Firebase (Auth, Firestore, Storage).
- **Blockchain :** Smart contracts Solidity déployés sur testnet Ethereum.
- **ML :** Modèle TensorFlow → TFLite.

### 4.2. Schéma Simplifié

```
Flutter App <——> Firebase (Auth, Firestore, Storage)
       \——> Smart Contract (Blockchain ETH Testnet)
       \——> ML Recommender (TFLite / Cloud Function)
```

### 4.3. Base de Données Firestore

**Collections principales :**

- `users` : infos utilisateur.
- `courses` : métadonnées des cours.
- `purchases` : historique d'achat.
- `progress` : suivi de visionnage.
- `recommendation_logs` : données d'entraînement ML.

---

## 5. Blockchain — Spécifications

### 5.1. Smart Contract Paiements

- Fonction `buyCourse(courseId)`.
- Enregistrement des transactions.
- Transfert d’ETH au formateur ou au contrat.

### 5.2. Smart Contract Certificats (ETH)

- Basé sur Ethereum (testnet Sepolia).
- Fonction `mintCertificate(address student, uint courseId)`.
- Paiement et certification tous deux sur la même blockchain ETH.
- Métadonnées (titre du cours, date, étudiant) stockées sur IPFS.
- Vérification via l'adresse ETH de l'étudiant.

### 5.3. Outils

- Solidity.
- Hardhat.
- RPC Provider (Infura/Alchemy).
- Testnet ( Sepolia).

---

## 6. Deep Learning — Spécifications

### 6.1. Objectif

Recommander les cours les plus pertinents selon :

- l’historique de visionnage,
- les catégories consultées,
- les préférences implicites.

### 6.2. Pipeline ML

1. Export des logs Firestore.
2. Entraînement d’un modèle léger (TensorFlow).
3. Conversion vers TFLite.
4. Téléchargement dans l’application.
5. Exécution locale ou via Cloud Function.

### 6.3. Type de Modèle

Matrix Factorization ou petit réseau dense (embedding + dense layers).

---

## 7. Interfaces Principales (Screens Flutter)

- Page d’accueil (recommandations).
- Liste des cours.
- Page détail cours.
- Lecteur vidéo.
- Achat via blockchain.
- Profil utilisateur.
- Certificats NFT.

---

##

---

## 8. Sécurité et Contraintes

- Utilisation d’un wallet testnet.
- Stockage sécurisé de la clé privée (flutter\_secure\_storage pour démo).
- Respect des limites Firebase (quota, règles sécurité Firestore).
- Transactions blockchain non annulables.

---

## 9. Livrables

- Code source Flutter.
- Code source Smart Contracts + projet Hardhat.
- Script d’entraînement ML + modèle TFLite.
- Documentation technique.
- Rapport final.

---

## 10. Conclusion

Ce cahier des charges décrit une application mobile moderne combinant apprentissage, technologie blockchain et intelligence artificielle. Le périmètre est réaliste, cohérent et valorisant pour un projet académique.

