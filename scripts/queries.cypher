// Similar to Boris

MATCH (p1Party:Party)<-[:MEMBER_OF]-(p1:Person)-[r1]->(m:Motion)
WHERE p1.name = "Boris Johnson"
MATCH (p2Party:Party)<-[:MEMBER_OF]-(p2:Person)-[r2]->(m)
WHERE p2 <> p1
WITH p1, p2, p2Party,
     CASE WHEN type(r1) = "FOR" THEN 5
          WHEN type(r1) = "DID_NOT_VOTE" THEN 0.5
          ELSE 0 END AS r1Score,
     CASE WHEN type(r2) = "FOR" THEN 5
          WHEN type(r2) = "DID_NOT_VOTE" THEN 0.5
          ELSE 0 END AS r2Score
WITH p2 AS to,
     p2Party.name AS party,
     algo.similarity.cosine(collect(r1Score), collect(r2Score))
     AS similarity
WHERE similarity = 1.0
RETURN count(*);

// Similar to Boris in other parties
MATCH (p:Person), (c:Motion)
OPTIONAL MATCH (p)-[vote]->(c)
WITH p, c,
     CASE WHEN type(vote) = "FOR" THEN 5
          WHEN type(vote) = "DID_NOT_VOTE" THEN 0.5
          ELSE 0 END AS score
ORDER BY p, c
WITH {item:id(p), weights: collect(score)} as userData
WITH collect(userData) as data
CALL algo.similarity.cosine.stream(data)
YIELD item1, item2, count1, count2, similarity

WITH algo.getNodeById(item1) AS from, algo.getNodeById(item2) AS to, similarity
RETURN from.name AS from, [(from)-[:MEMBER_OF]->(party) | party.name][0] AS fromParty,
       to.name AS to, [(to)-[:MEMBER_OF]->(party) | party.name][0] AS toParty,
       similarity
ORDER BY similarity DESC;

// Create Similarities Graph

MATCH (p:Person), (c:Motion)
OPTIONAL MATCH (p)-[vote]->(c)
WITH p, c,
     CASE WHEN type(vote) = "FOR" THEN 5
          WHEN type(vote) = "DID_NOT_VOTE" THEN 0.5
          ELSE 0 END AS score
ORDER BY p, c
WITH {item:id(p), weights: collect(score)} as userData
WITH collect(userData) as data
CALL algo.similarity.cosine(data, {similarityCutoff: 1.0, write: true})
YIELD nodes, similarityPairs, write, writeRelationshipType, writeProperty, min, max, mean, stdDev, p25, p50, p75, p90, p95, p99, p999, p100
RETURN nodes, similarityPairs, write, writeRelationshipType, writeProperty, min, max, mean, p95;

// Run Connected Components over that graph

CALL algo.unionFind.stream('Person', 'SIMILAR', {direction: "BOTH"})
YIELD nodeId,setId
WITH setId, collect(algo.getNodeById(nodeId)) AS nodes
MERGE (community:Community {id: setId, type: "Connected Components"})
WITH community, nodes
UNWIND nodes AS node
MERGE (node)-[:IN_COMMUNITY]->(community);

// Communities of MPs and which motions they voted for
MATCH (c:Community)
WITH c, size((c)<-[:IN_COMMUNITY]-()) AS size
WHERE size > 10

MATCH (c)<-[rel:IN_COMMUNITY]-(person)
WITH c, rel, size, person
ORDER BY person.pageviews DESC

WITH c, collect({person: person, rel:rel })[..3] AS topPeople, size
WITH c, topPeople, topPeople[0].person AS person, size
WITH c, topPeople, size, [(person)-[:FOR]->(motion:Motion) | motion] AS votes
       
UNWIND votes AS vote       
CALL apoc.create.vRelationship(c,"FOR",{},vote) yield rel
RETURN *;