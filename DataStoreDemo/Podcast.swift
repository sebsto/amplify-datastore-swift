//
//  Data.swift
//  DataStoreDemo
//
//  Created by Stormacq, Sebastien on 05/11/2022.
//

import Foundation
import SwiftUI

/**
GraphQL structure
 
 ```
    type Podcast @model {
        id: ID!
        name: String!
        category: PodcastCategory!
        author: String
        rating: Int
        episodes: [String]
        image: String
    }
 
    type Episode @model {
 
        id: ID!
        title: String!
        duration: String
        description: String
    }

    enum PodcastCategory {
        Technology
        Comedy
        Cloud
    }
 ```
 */

struct Podcast: Identifiable, Hashable, Codable {
    
    enum Category: String, Identifiable, Hashable, CaseIterable, Codable {
        var id: String { rawValue }
        var name: String { rawValue.localizedCapitalized }
        var icon: Image {
            switch self {
                case .cloud: return Image(systemName: "cloud")
                case .comedy: return Image(systemName: "face.smiling")
                case .technology: return Image(systemName: "wrench.and.screwdriver")
            }
        }
        case cloud
        case comedy
        case technology
    }

    struct Episode: Identifiable, Hashable, Codable {
        let id: String
        let date: String
        let title: String
        let duration: String
        let description: String?
    }

    let id: String
    let name: String
    let category: Category
    let author: String
    let rating: Int?
    let image: String?
    var episodes: [Episode]?
}

final class ImageStore {
    typealias _ImageDictionary = [String: CGImage]
    fileprivate var images: _ImageDictionary = [:]
    
    fileprivate static var scale = 2
    
    static var shared = ImageStore()
    
    func image(name: String) -> Image {
        let index = _guaranteeImage(name: name)
        
        return Image(images.values[index], scale: CGFloat(ImageStore.scale), label: Text(verbatim: name))
    }
    
    static func loadImage(name: String) -> CGImage {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
            let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            fatalError("Couldn't load image \(name).jpg from main bundle.")
        }
        return image
    }
    
    fileprivate func _guaranteeImage(name: String) -> _ImageDictionary.Index {
        if let index = images.index(forKey: name) { return index }
        
        images[name] = ImageStore.loadImage(name: name)
        return images.index(forKey: name)!
    }
}


/**
extension Podcast {
    
    static let data: [Podcast] = [
        Podcast(id: "001", name: "Le podcast 🎙 AWS ☁️ en 🇫🇷", category: .cloud, author: "Sébastien Stormacq", rating: 10, image: "podcast-aws-francais", episodes:[
            Episode(id: "001-003", date: "04 NOV. 2022", title: "Renovate", duration: "00:34:00", description: "La gestion des dépendances dans un projet peut rapidement devenir une tâche à plein temps. Garder ses packages à jours est important pour sécuriser vos usines de production de logiciels. Il existe des outils qui automatisent ces tâches et vous propose automatiquement des pull request sur vos repos. Un de ces outils s'appelle Renovate de Mend. Renovate est disponible en version open-source comme une app GitHub que vous pouvez intégrer en quelques clicks dans vos applications. Dans cet épisode, j'ai eu une conversation avec Swissquote, une sociéte Suisse qui utilise Renovate depuis trois sans sur plusieurs centaines d'entrepôts de code."),
            Episode(id: "001-002", date: "28 OCT. 2022", title: "Quoi de neuf ?", duration: "00:13:00", description: "Beaucoup de nouveautés cette semaine. J'ai retenu celles qui peuvent influencer notre travail de développeurs, de builders. Je parlerai dans cet épisode de App Runner, de Amplify Libraries pour le language de programmation Swift. Il sera désormais plus facile d'accéder à Parameter Store et Secrets Manager depuis Lambda. Les locale Zones débarquent en Europe. Je parlerai de EC2 qui permet de remplacer le volume principal sans arrêter complètement votre machine. Et je terminerai avec des nouveautés dans la console AWS et dans la console sur mobile."),
            Episode(id: "001-001", date: "21 OCT. 2022", title: "Air Caraibes", duration: "00:36:00", description: "Air Caraibes est la compagnie aérienne des antilles, née de la fusion entre plusieurs compagnies locales et de la volonté d'un grand groupe industriel français. J'ai rencontré Noella (DSI) et Jean-Michel (RSSI) à Fort-de-France où nous avions organisé une conférence en Septembre 2022. Nous avons parlé du métier de transporteur aérien et des détails de leur projet - toujours en cours - de migration vers le cloud AWS. Nous y parlons techniques de migration, FinOps, GreenIT, et aussi de la motivation des équipes pour travailler avec les technologies du cloud et du poids du cloud dans le recrutement. PNC aux portes, vérification de la porte opposée. Bon voyage vers le cloud."),
        ]),

        Podcast(id: "002", name: "Charlas Technicas", category: .cloud, author: "Marcia Villalba", rating: 10, image: "charlas-technicas", episodes: [
            Episode(id: "002-003", date: "31 OCT 2022", title: "Introducción a Arquitecturas Orientadas a Eventos", duration: "01:01:00", description: "En este episodio hablamos con Jaime González, CTO de Pentasoft, que nos cuenta sobre arquitecturas orientadas a eventos y como lo ponen en práctica en producción en los productos SaaS que hacen en Pentasoft."),
            Episode(id: "002-002", date: "17 OCT 2022", title: "Cómo migrar más de 1000 aplicaciones a la nube?", duration: "01:11:00", description: "En este episodio hablamos con Alberto Menendez y Alexander Cabezas sobre como es migrar 600, 1000 o más aplicaciones a la nube. Ellos trabajan para AWS haciendo este tipo de migraciones y nos cuentan sus experiencias."),
            Episode(id: "002-001", date: "3 OCT. 2022", title: "Emprendiendo en la nube", duration: "01:17:00", description: "En este episodio hablamos con Alvaro Hernandez sobre como es montar una empresa técnologica siendo técnico. Este es un episodio poco convencional para el podcast pero me parecio super interesante el tema. Ya me diran en los comentarios :)"),
        ]),

        Podcast(id: "003", name: "The AWS Podcast", category: .cloud, author: "Simon Elisha", rating: 10, image: "podcast-aws", episodes: [
            Episode(id: "003-003", date: "31 OCT. 2022", title: "Protect Your Data With AWS Backup for Amazon S3", duration: "00:14:00", description: "Data continues to grow at an exponential rate, and it is leveraged for customer insights and experiences as well as AI/ML engines. That application data is valuable and needs protection against the all manners of disasters from natural, to accidental, to intentionally malicious. In highly regulated industries, customers need to audit and report on the compliance of their data against organizational or regulatory standards. Tune in for Simon's chat with Murtaza Chowdhury, Head of Product for AWS Backup, where they'll cover AWS Backup’s support for Amazon S3 and how it can help you centralize data protection for S3 resources alongside other supported AWS compute, database, and storage services."),
            Episode(id: "003-002", date: "24 OCT 2022", title: "October 2022 Update Show 2", duration: "00:29:00", description: "Simon & Hawn walk you through all the latest updates!!\nChapters:\n01:06 Analytics\n04:19 Business Applications\n05:44 Compute\n16:05 Cost Management\n16:41 Database\n18:32 End User Computing\n20:31 Machine Learning\n21:15 Management & Governance\n22:54 Migration and Transfer\n23:57 Networking & Content Delivery\n26:49 Security, Identity and Compliance\n27:45 Start-ups\nExtended Shownotes: https://d29iemol7wxagg.cloudfront.net/552ExtendedShownotes.html"),
            Episode(id: "003-001", date: "17 OCT. 2022", title: "Deep Dive Into SageMaker Serverless Inference", duration: "00:17:00", description: "Deep Dive Into SageMaker Serverless Inference"),
        ]),

        Podcast(id: "004", name: "Underscore", category: .technology, author: "Matthieu Lambda", rating: 8, image: "underscore", episodes: [
            Episode(id: "004-003", date: "1 NOV. 2022", title: "Les GIFs ont un intérêt tout particulier pour Facebook ", duration: "00:16:00", description: "Facebook a racheté un moteur de recherche de GIF pour... 400 millions de dollars !!? Mais diable, pourquoi ça intéresse autant Facebook ? Matthieu Lambda revient sur les raisons d'un tel rachat, et ça pourrait bien vous surprendre !"),
            Episode(id: "004-002", date: "31 OCT. 2022", title: "Toutes les questions qu'on a toujours voulu poser à David Louapre", duration: "00:41:00", description: "On a reçu David Louapre de Science Étonnante, et dire qu'il est passionnant est un euphémisme !"),
            Episode(id: "004-001", date: "28 OCT. 2022", title: "S3E3 - La face cachée (et inattendue) des entreprises de GIFs", duration: "01:50:00", description: "Cette semaine dans Underscore_, un peu plus de science que d'habitude !\nOn commence par poser toutes les questions qu'on a toujours voulu poser à David Louapre, créateur de la chaîne Science Étonnante. Ensuite, on simule la sélection naturelle (rien que ça) et enfin, on parle de Giphy, et de son intérêt inattendu pour les géants de la tech."),
        ]),

        Podcast(id: "005", name: "Les Technos", category: .technology, author: "Marc Lescroart", rating: 10, image: "les-technos", episodes: [
            Episode(id: "005-003", date: "03 NOV. 2022", title: "Twitter à 8$, Lego Mindstorms, plus vite avec moonwalker, Constellr,...", duration: "00:59:00", description: "Episode 374 avec Xavier et David.\n\nSommaire :\n• E comme Espace (00:02:15) : Constellr: des satellites pour aider le secteur agricole. La startup Constellr veut aider le secteur agricole à lutter contre la famine grâce à des satellites. (source) \n• I comme Intelligence Artificielle (00:09:12) : Réaction furieuse de la communauté \"anime\" face à l'art IA. L'art généré par IA déclenche une réaction furieuse de la part de la communauté \"anime\" Japonaise (Manga. (source) \n• L comme Lego (00:18:52) : Lego annonce la fin de toute une gamme après 24 ans. Lego met fin à la gamme Mindstorms après 24 ans. (source, source) \n• O comme Openssl (00:25:29) : Faille majeure corrigée. OpenSSL corrige deux vulnérabilités à très haute sévérité. (source) \n• R comme Roulettes (00:33:12) : Avec les moonwalker vous marcherez 250% plus vite. Des chaussures motorisées Moonwalker augmentent fortement la vitesse de marche. (source) \n• S comme Smartphone (00:38:13) : Samsung dévoile un mode maintenance pour ses smartphones. Samsung dévoile un mode maintenance sur les smartphones pour lutter contre les réparateurs indiscrets. (source) \n• T comme Twitter (00:43:05) : Devenez un Seigneur pour 8$. Elon musk, propose de payer 8$ pour être un \"seigneur\" vérifier sur Twitter. (source) \n• W comme Wemenon (00:53:37) : Bientôt la guerre dans l'espace? La Chine envisage les armes nucléaires pour lutter contre Starlink. (source)"),
            Episode(id: "005-002", date: "31 OCT. 2022", title: "Da Vinci Resolve pour iPad, Amazon achète des Airbus", duration: "00:15:00", description: "Dans notre bonus 373 avec Benoit et Sébastien S.\n\n• Blackmagic Design : Da Vinci Resolve pour iPad (source)\n• Apple App Store : Quand l'App Store devient un casino géant (source)\n• Effets spéciaux : La galère des spécialistes (source)\n• Prime Air : Quand Amazon achete des Airbus d'occasion (source, source)"),
            Episode(id: "005-001", date: "27 OCT. 2022", title: "Kindle Scribe, cuiseur passif Barilla, Microsoft Voltera, PassKeys", duration: "00:52:00", description: "Episode 373 avec Benoit et Sébastien S.\n\nSommaire :\n• B comme BugBounty (00:02:50) : Quand un developer capture l'audio des AirPods. Un developpeur decouvre un bug dans iOS/macOS et empoche $7000 de bug bounty. (source) \n• C comme CoffeB (00:09:11) : What else? Coffee balls. Le système à capsule sans capsule. (source, source) \n• E comme Emulateurs (00:13:56) : Quand des passionnés émulent en JavaScript. Des emulateurs JavaScript pour Windows95, macOS 6 et 7. (source, source) \n• K comme Kindle (00:19:39) : Kindle Scribe. La première liseuse 10.2’’ avec stylet d'Amazon. (source, source) \n• P comme PassKeys (00:26:18) : Quand les Passkeys deviennent réalité. Les premiers sites web qui proposent PassKey arrivent. Plus de mot de passe. (source, source) \n• P comme Pâtes (00:33:35) : Le cuisseur passif Barilla. Un mode alternatif de cuisson des pâtes qui contribue à réduire les émissions de CO₂ jusqu’à 80%* par rapport à la méthode traditionnelle (*selon Barilla). (source) \n• U comme Uber (00:44:01) : Le déséquilibre des forces. Mark MacGann dit aux eurodéputés qu'Uber disposait d'un \"financement presque illimité\" pour faire taire les conducteurs ayant des différends juridiques. (source) \n• V comme Voltera (00:44:56) : Quand Microsoft vend des PCs Arm. Microsoft vend des kits de developpements Arm aux développeurs . (source, source))"),
        ]),

        Podcast(id: "006", name: "Le billet de Charline Vanhœnacker", category: .comedy, author: "France Inter", rating: 9, image: "charline", episodes: [
            Episode(id: "006-003", date: "03 NOV. 2022", title: "Les hommes à la crèche", duration: "00:03:02", description: "Les crèches aussi font face à une pénurie de personnel…"),
            Episode(id: "006-002", date: "02 NOV. 2022", title: "Aux ministres inconnus", duration: "00:03:20", description: "Le gouvernement est en place depuis 5 mois et la majorité des ministres sont toujours inconnus des Français…"),
            Episode(id: "006-001", date: "01 NOV. 2022", title: "En cendres, tout devient possible", duration: "00:02:56", description: "Nous sommes le 1er novembre et depuis quelques jours, il est paru des tonnes d’articles de presse sur la mort…"),
        ]),
    ]
}
*/
