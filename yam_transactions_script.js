// Importation de Winston pour le logging
const winston = require('winston');
const { Pool } = require('pg');
const { pow } = Math;

// Configuration du logger avec Winston
const logger = winston.createLogger({
  level: 'info', // Peut être ajusté à 'debug' en phase de développement
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => `[${level.toUpperCase()}]: ${message}`)
  ),
  transports: [
    new winston.transports.Console(),
    // Vous pouvez activer le logging dans un fichier en décommentant la ligne suivante :
    // new winston.transports.File({ filename: 'app.log' })
  ]
});

logger.info('========================================================================================');
logger.info('=============================== YAM Transactions History ===============================');
logger.info('========================================================================================')

// === CONFIGURATION ===

// Endpoint TheGraph
const GRAPHQL_ENDPOINT = "https://gateway-arbitrum.network.thegraph.com/api/ae36a6bfa6af7dfa3487d2cecf583ebe/subgraphs/id/4eJa4rKCR5f8fq48BKbYBPvf7DWHppGZRvfiVUSFXBGR";

// Configuration des tailles de lots
let WALLET_BATCH_SIZE = 15; // Traiter 15 wallets à la fois
const MIN_BATCH_SIZE = 5;    // Taille minimale en cas d'erreurs répétées

// Configuration PostgreSQL
const pool = new Pool({
  host: 'postgres',
  database: 'realtoken',
  user: 'nocodb',
  password: 'nocodbpassword',
  port: 5432,
});

// === QUERY TheGraph ===

const query = `
query GetYamPurchases($buyers: [String!]!, $skip: Int!) {
  purchases(
    first: 1000
    skip: $skip
    where: {buyer_in: $buyers}
    orderBy: createdAtTimestamp
    orderDirection: asc
  ) {
    seller {
      address
    }
    buyer {
      address
    }
    price
    quantity
    id
    createdAtTimestamp
    offer {
      buyerToken {
        address
      }
      offerToken {
        address
      }
    }
  }
}
`;

// Fonction utilitaire pour diviser un array en chunks
function chunkArray(array, chunkSize) {
  const chunks = [];
  for (let i = 0; i < array.length; i += chunkSize) {
    chunks.push(array.slice(i, i + chunkSize));
  }
  return chunks;
}

/**
 * Récupère les wallets depuis la table PostgreSQL.
 * @returns {Promise<Array<string>>} - Un tableau d'adresses Ethereum en minuscules.
 */
async function getWallets() {
  try {
    const client = await pool.connect();
    try {
      const result = await client.query('SELECT address FROM address_list');
      const wallets = result.rows
        .map(rec => rec.address && rec.address.toLowerCase())
        .filter(address => address);
      logger.info(`Récupération de ${wallets.length} wallets depuis PostgreSQL.`);
      return wallets;
    } finally {
      client.release();
    }
  } catch (err) {
    logger.error(`Erreur lors de la récupération des wallets depuis PostgreSQL: ${err.message}`);
    return [];
  }
}

/**
 * Exécute la query TheGraph pour récupérer les purchases pour un lot de wallets.
 * @param {Array<string>} walletBatch - Liste des wallets (buyers).
 * @param {number} skip - Nombre d'éléments à sauter (pagination).
 * @param {number} retryCount - Nombre de tentatives restantes.
 * @returns {Promise<Array>} - Tableau des purchases pour ce lot de wallets.
 */
async function fetchYamTransactions(walletBatch, skip = 0, retryCount = 3) {
  const variables = { buyers: walletBatch, skip };

  try {
    const response = await fetch(GRAPHQL_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables }),
      timeout: 30000 // 30 secondes de timeout
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`HTTP ${response.status}: ${errorText}`);
    }

    const data = await response.json();
    
    // Vérifier la structure de la réponse
    if (!data) {
      throw new Error('Réponse vide de l\'API GraphQL');
    }
    
    if (data.errors && data.errors.length > 0) {
      throw new Error(`Erreurs GraphQL: ${data.errors.map(e => e.message).join(', ')}`);
    }
    
    if (!data.data) {
      throw new Error('Pas de données dans la réponse GraphQL');
    }
    
    if (!data.data.purchases) {
      logger.warn(`Aucun purchase trouvé dans la réponse pour ce lot (skip: ${skip})`);
      return [];
    }

    return data.data.purchases;
  } catch (err) {
    logger.error(`Erreur lors de la récupération des purchases depuis TheGraph: ${err.message}`);
    
    // Retry logic avec backoff exponentiel
    if (retryCount > 0) {
      const waitTime = (4 - retryCount) * 2000; // 2s, 4s, 6s
      logger.info(`⏳ Nouvelle tentative dans ${waitTime/1000}s... (${retryCount} tentatives restantes)`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
      return fetchYamTransactions(walletBatch, skip, retryCount - 1);
    }
    
    throw err;
  }
}

/**
 * Récupère toutes les purchases pour un lot de wallets avec pagination automatique
 * @param {Array<string>} walletBatch - Lot de wallets à traiter
 * @returns {Promise<Array>} - Toutes les purchases pour ce lot
 */
async function fetchYamTransactionsForBatch(walletBatch) {
  logger.info(`🔄 Traitement du lot: ${walletBatch.length} wallets`);
  
  let allPurchases = [];
  let skip = 0;
  let hasMoreData = true;
  let consecutiveErrors = 0;
  const MAX_SKIP = 5000; // Limite TheGraph

  while (hasMoreData && consecutiveErrors < 3 && skip <= MAX_SKIP) {
    try {
      const purchases = await fetchYamTransactions(walletBatch, skip);
      consecutiveErrors = 0; // Reset error counter sur succès
      
      if (!purchases || purchases.length === 0) {
        hasMoreData = false;
      } else {
        allPurchases = allPurchases.concat(purchases);
        skip += 1000;
        
        // Vérifier si on atteint la limite de skip
        if (skip > MAX_SKIP) {
          logger.warn(`⚠️ Limite de pagination atteinte (skip > ${MAX_SKIP}). Données potentiellement incomplètes pour ce lot.`);
          hasMoreData = false;
        } else if (purchases.length < 1000) {
          hasMoreData = false;
        } else {
          logger.info(`  📄 Page récupérée: ${purchases.length} purchases (skip: ${skip - 1000})`);
        }
      }
    } catch (err) {
      consecutiveErrors++;
      logger.error(`❌ Erreur lors du traitement de la page (skip: ${skip}) pour ce lot: ${err.message}`);
      
      // Si c'est une erreur liée au skip, arrêter immédiatement
      if (err.message.includes('skip') && err.message.includes('5000')) {
        logger.warn(`⚠️ Limite de skip TheGraph atteinte (${skip}). Arrêt de la pagination pour ce lot.`);
        break;
      }
      
      if (consecutiveErrors >= 3) {
        logger.error(`❌ Trop d'erreurs consécutives (${consecutiveErrors}), abandon du lot`);
        break;
      } else {
        logger.info(`⏳ Pause de 5 secondes avant de continuer...`);
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
  }

  if (consecutiveErrors >= 3) {
    logger.warn(`⚠️ Lot partiellement traité: ${allPurchases.length} purchases récupérées (avec erreurs)`);
  } else if (skip > MAX_SKIP) {
    logger.warn(`⚠️ Lot limité par pagination: ${allPurchases.length} purchases récupérées (limite skip: ${MAX_SKIP})`);
  } else {
    logger.info(`  ✅ Lot terminé: ${allPurchases.length} purchases récupérées`);
  }
  
  return allPurchases;
}

/**
 * Récupère tous les enregistrements existants dans la table PostgreSQL
 * et construit un ensemble de clés composites au format "accountId_transactionId".
 */
async function getAllExistingTransactionKeys() {
  const existingKeys = new Set();

  logger.info("Récupération de tous les enregistrements de transactions depuis PostgreSQL...");

  try {
    const client = await pool.connect();
    try {
      const result = await client.query('SELECT account_id, transaction_id FROM yam_transactions_history');
      
      result.rows.forEach(rec => {
        const accountId = rec.account_id?.toLowerCase().trim();
        const transactionId = rec.transaction_id?.toLowerCase().trim();

        if (!accountId || !transactionId) {
          logger.warn(`Transaction ignorée (champs manquants) : ${JSON.stringify(rec)}`);
          return;
        }
        existingKeys.add(`${accountId}_${transactionId}`);
      });

      logger.info(`Nombre total d'enregistrements existants récupérés: ${existingKeys.size}`);
      return existingKeys;
    } finally {
      client.release();
    }
  } catch (err) {
    logger.error(`Erreur dans getAllExistingTransactionKeys: ${err.message}`);
    throw err;
  }
}

/**
 * Envoie les enregistrements dans la table PostgreSQL avec gestion des doublons.
 * @param {Array<Object>} records - Tableau d'enregistrements à insérer.
 */
async function storeTransactions(records) {
  if (records.length === 0) {
    logger.info("🚀 Aucune nouvelle transaction à stocker.");
    return;
  }

  // Dédoublonner les records au cas où il y aurait des doublons dans les données
  const uniqueRecords = [];
  const seenKeys = new Set();
  
  for (const record of records) {
    const key = `${record.accountId.toLowerCase().trim()}_${record.transactionId.toLowerCase().trim()}`;
    if (!seenKeys.has(key)) {
      seenKeys.add(key);
      uniqueRecords.push(record);
    }
  }

  if (uniqueRecords.length < records.length) {
    logger.warn(`⚠️ ${records.length - uniqueRecords.length} doublons détectés et supprimés dans les nouvelles données`);
  }

  try {
    const client = await pool.connect();
    try {
      // Compter les transactions existantes avant insertion
      const countBefore = await client.query(`
        SELECT COUNT(*) as count FROM yam_transactions_history
      `);

      // Création d'une table temporaire pour le batch insert
      await client.query(`
        CREATE TEMP TABLE temp_yam_transactions (
          account_id text,
          transaction_id text,
          price numeric,
          quantity numeric,
          taker text,
          timestamp text,
          offer_id text,
          offer_token_address text,
          buyer_token_address text,
          maker text
        )
      `);

      // Insertion des données dans la table temporaire
      for (const record of uniqueRecords) {
        await client.query(`
          INSERT INTO temp_yam_transactions (
            account_id, transaction_id, price, quantity, taker,
            timestamp, offer_id, offer_token_address,
            buyer_token_address, maker
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        `, [
          record.accountId,
          record.transactionId,
          record.price,
          record.quantity,
          record.taker,
          record.createdAtTimestamp,
          record.offerId,
          record.offerTokenAddress,
          record.buyerTokenAddress,
          record.maker
        ]);
      }

      // Insertion des données de la table temporaire vers la table principale
      // Utilise ON CONFLICT pour éviter les erreurs de doublons
      await client.query(`
        INSERT INTO yam_transactions_history (
          account_id, transaction_id, price, quantity, taker,
          timestamp, offer_id, offer_token_address,
          buyer_token_address, maker
        )
        SELECT * FROM temp_yam_transactions
        ON CONFLICT (account_id, transaction_id) DO NOTHING
      `);

      // Compter les transactions après insertion pour voir combien ont été réellement ajoutées
      const countAfter = await client.query(`
        SELECT COUNT(*) as count FROM yam_transactions_history
      `);

      const actuallyInserted = parseInt(countAfter.rows[0].count) - parseInt(countBefore.rows[0].count);
      const duplicatesSkipped = uniqueRecords.length - actuallyInserted;

      logger.info(`✅ ${actuallyInserted} nouvelles transactions ajoutées`);
      if (duplicatesSkipped > 0) {
        logger.warn(`⚠️ ${duplicatesSkipped} transactions ignorées (déjà existantes)`);
      }
    } finally {
      client.release();
    }
  } catch (err) {
    logger.error(`Erreur lors du stockage des transactions: ${err.message}`);
    throw err;
  }
}

/**
 * Fonction principale pour récupérer, convertir et stocker les transactions,
 * en évitant les doublons basés sur la combinaison transactionId et accountId.
 */
async function main() {
  try {
    const wallets = await getWallets();
    if (wallets.length === 0) {
      logger.info("Aucun wallet trouvé dans PostgreSQL.");
      return;
    }

    // Diviser les wallets en lots
    const walletBatches = chunkArray(wallets, WALLET_BATCH_SIZE);
    logger.info(`📊 Traitement par lots: ${walletBatches.length} lots de ${WALLET_BATCH_SIZE} wallets maximum`);

    const existingKeys = await getAllExistingTransactionKeys();
    let allNewRecords = [];
    let batchCount = 0;

    // Traiter chaque lot de wallets
    let successfulBatches = 0;
    let failedBatches = 0;
    let consecutiveFailures = 0;
    
    for (const walletBatch of walletBatches) {
      batchCount++;
      logger.info(`\n🔄 Traitement du lot ${batchCount}/${walletBatches.length} (${walletBatch.length} wallets)`);

      try {
        const purchases = await fetchYamTransactionsForBatch(walletBatch);
        logger.info(`Purchases récupérées: ${purchases.length} pour ce lot`);

        const batchRecords = [];
        for (const purchase of purchases) {
          // Mapper les champs de l'API purchases vers l'ancienne structure de table
          const record = {
            accountId: purchase.buyer ? purchase.buyer.address : null, // buyer.address -> account_id
            transactionId: purchase.id,
            price: parseFloat(purchase.price),
            quantity: parseFloat(purchase.quantity),
            taker: purchase.seller ? purchase.seller.address : null, // seller.address -> taker
            createdAtTimestamp: purchase.createdAtTimestamp,
            offerId: null, // Pas disponible dans la nouvelle API purchases
            offerTokenAddress: purchase.offer && purchase.offer.offerToken ? purchase.offer.offerToken.address : null,
            buyerTokenAddress: purchase.offer && purchase.offer.buyerToken ? purchase.offer.buyerToken.address : null,
            maker: null // Pas disponible dans la nouvelle API purchases
          };
          batchRecords.push(record);
        }

        // Filtrer les nouvelles transactions pour ce lot
        const newRecords = batchRecords.filter(r => {
          if (!r.accountId) return false; // Skip si pas d'accountId
          const key = `${r.accountId.toLowerCase().trim()}_${r.transactionId.toLowerCase().trim()}`;
          return !existingKeys.has(key);
        });

        allNewRecords = allNewRecords.concat(newRecords);
        logger.info(`  🔍 ${newRecords.length} nouvelles transactions dans ce lot`);
        successfulBatches++;
        consecutiveFailures = 0; // Reset sur succès
        
        // Si le lot a atteint la limite de pagination, réduire la taille pour les suivants
        if (purchases.length >= 5000 && WALLET_BATCH_SIZE > MIN_BATCH_SIZE) {
          const oldSize = WALLET_BATCH_SIZE;
          WALLET_BATCH_SIZE = Math.max(MIN_BATCH_SIZE, Math.floor(WALLET_BATCH_SIZE * 0.7));
          logger.info(`📉 Lot volumineux détecté (${purchases.length} purchases). Réduction préventive: ${oldSize} → ${WALLET_BATCH_SIZE} wallets`);
          
          // Redécouper les lots restants si nécessaire
          if (batchCount < walletBatches.length) {
            let remainingWallets = [];
            for (let i = batchCount; i < walletBatches.length; i++) {
              remainingWallets = remainingWallets.concat(walletBatches[i]);
            }
            
            if (remainingWallets.length > 0) {
              logger.info(`🔄 Redécoupage préventif des ${remainingWallets.length} wallets restants...`);
              const newBatches = chunkArray(remainingWallets, WALLET_BATCH_SIZE);
              walletBatches.splice(batchCount, walletBatches.length - batchCount, ...newBatches);
              logger.info(`📊 ${newBatches.length} nouveaux lots créés avec la taille réduite`);
            }
          }
        }
        
      } catch (err) {
        failedBatches++;
        consecutiveFailures++;
        logger.error(`❌ Erreur lors du traitement du lot ${batchCount}: ${err.message}`);
        
        // Si trop d'échecs consécutifs, proposer de réduire la taille des lots
        if (consecutiveFailures >= 3 && WALLET_BATCH_SIZE > MIN_BATCH_SIZE) {
          const oldSize = WALLET_BATCH_SIZE;
          WALLET_BATCH_SIZE = Math.max(MIN_BATCH_SIZE, Math.floor(WALLET_BATCH_SIZE / 2));
          logger.warn(`⚠️ Trop d'échecs consécutifs (${consecutiveFailures}). Réduction de la taille des lots: ${oldSize} → ${WALLET_BATCH_SIZE}`);
          
          // Collecter tous les wallets des lots restants (à partir du suivant)
          let remainingWallets = [];
          for (let i = batchCount; i < walletBatches.length; i++) {
            remainingWallets = remainingWallets.concat(walletBatches[i]);
          }
          
          if (remainingWallets.length > 0) {
            logger.info(`🔄 Redécoupage des ${remainingWallets.length} wallets restants en lots de ${WALLET_BATCH_SIZE}...`);
            const newBatches = chunkArray(remainingWallets, WALLET_BATCH_SIZE);
            // Remplacer tous les lots restants par les nouveaux lots plus petits
            walletBatches.splice(batchCount, walletBatches.length - batchCount, ...newBatches);
            logger.info(`📊 Nouveaux lots créés: ${newBatches.length} lots (au lieu de ${walletBatches.length - batchCount + newBatches.length})`);
            consecutiveFailures = 0; // Reset après redécoupage
          }
        } else {
          logger.info(`⏭️ Passage au lot suivant...`);
        }
      }

      // Petite pause entre les lots pour éviter de surcharger l'API
      if (batchCount < walletBatches.length) {
        const pauseTime = consecutiveFailures > 0 ? 2000 : 500; // Pause plus longue après erreurs
        await new Promise(resolve => setTimeout(resolve, pauseTime));
      }
    }

    logger.info(`\n📊 Résumé du traitement:`);
    logger.info(`  ✅ Lots réussis: ${successfulBatches}/${walletBatches.length}`);
    logger.info(`  ❌ Lots échoués: ${failedBatches}/${walletBatches.length}`);

    logger.info(`\n📦 Total: ${allNewRecords.length} nouvelles transactions à insérer`);

    if (allNewRecords.length > 0) {
      await storeTransactions(allNewRecords);
    } else {
      logger.info("Aucune nouvelle transaction à insérer.");
    }
  } catch (err) {
    logger.error(`Erreur dans main: ${err.message}`);
  } finally {
    await pool.end();
  }
}

// Lancer le script
main(); 