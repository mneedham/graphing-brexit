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
MATCH (c:Community {type: "Connected Components"})
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

// Similarities Graph based on FOR relationships

MATCH (p:Person)-[:FOR]->(motion:Motion)
WITH {item:id(p), categories: collect(id(motion))} as userData
WITH collect(userData) as data
CALL algo.similarity.jaccard(data, {
  similarityCutoff: 1.0, 
  write:true, 
  writeRelationshipType: "SIMILAR_FOR"
})
YIELD nodes, similarityPairs, writeRelationshipType, writeProperty
RETURN nodes, similarityPairs, writeRelationshipType, writeProperty;

// Run Connected Components over that graph
CALL algo.unionFind.stream('Person', 'SIMILAR_FOR', {direction: "BOTH"})
YIELD nodeId,setId
WITH setId, collect(algo.getNodeById(nodeId)) AS nodes
MERGE (community:Community {id: setId, type: "Connected Components FOR"})
WITH community, nodes
UNWIND nodes AS node
MERGE (node)-[:IN_COMMUNITY]->(community);

// Communities of MPs and which motions they voted for
MATCH (c:Community {type: "Connected Components FOR"})
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

// Find votes on a motion grouped by the party the person represented at that time
MATCH (p:Person)-[:FOR]->(motion:Motion {division: "439"})
WITH p,  [(p)-[memberOf:MEMBER_OF]->(party) 
          WHERE memberOf.start <= motion.date AND (not(exists(memberOf.end)) OR motion.date <= memberOf.end) | 
          party.name][0] AS parties
return parties, count(*) 
ORDER BY count(*) DESC

// People changing party allegiance
MATCH (p:Person)-[memberOf:MEMBER_OF]->(party:Party)
WHERE exists(memberOf.end)
WITH p, memberOf, party
MATCH (p)-[nextMemberOf:MEMBER_OF]->(newParty:Party)
WHERE nextMemberOf.start > memberOf.end
WITH p, memberOf, party, newParty, nextMemberOf
ORDER By p, nextMemberOf.start 
RETURN p.name, memberOf.end, party.name, collect(newParty.name)[0]
ORDER BY memberOf.end


// Which party did an MP vote most similarly to?
MATCH (person:Person {name: "Boris Johnson"})-[vote]->(m:Motion {date: date({year: 2019, month: 3, day: 27})})
MATCH (party:Party)-[ave:AVERAGE_VOTE]->(m)
RETURN person.name,
       party.name,
       algo.similarity.cosine(
         collect(CASE WHEN type(vote) = "FOR" THEN 1 WHEN type(vote) = "DID_NOT_VOTE" THEN 0.5 ELSE 0 END), 
         collect(ave.score)) AS similarity
ORDER BY similarity DESC

// Evicted Conservative MPS
MATCH (person:Person)-[vote]->(m:Motion {date: date({year: 2019, month: 3, day: 27})})
WHERE (person)-[:MEMBER_OF {end: date({year: 2019, month: 9, day: 3})}]->(:Party {name: "Conservative"})
MATCH (party:Party)-[ave:AVERAGE_VOTE]->(m) WHERE party.name <> "Speaker"
WITH person, party,
     algo.similarity.cosine(
      collect(CASE WHEN type(vote) = "FOR" THEN 1 WHEN type(vote) = "DID_NOT_VOTE" THEN 0.5 ELSE 0 END), 
      collect(ave.score)) AS similarity
ORDER BY similarity DESC
WITH person, collect({party: party.name, score: similarity}) AS parties
RETURN person.name, parties[0].party, parties[0].score