UNWIND [655,656,657,658,659,660,661,662,711, 669, 668, 667, 666, 664] AS division
LOAD CSV FROM "https://github.com/mneedham/graphing-brexit/raw/master/data/commonsvotes/Division" + division + ".csv" AS row
// Create motion nodes
WITH division, collect(row) AS rows
MERGE (motion:Motion {division: trim(split(rows[0][0], ":")[1]) })
SET motion.name = rows[2][0], 
    motion.date = date(datetime({epochmillis:apoc.date.parse(trim(split(rows[1][0], ":")[1]), "ms", "dd/MM/yyyy")}))
// Skip the first 6 rows as they have metadata we don't need
WITH motion, rows
UNWIND rows[7..] AS row
// Create person, party, constituency, and corresponding rels
MERGE (person:Person {name: row[0]})
MERGE (constituency:Constituency {name: row[2]})
MERGE (person)-[:REPRESENTS]->(constituency)
WITH person, motion,  
     CASE WHEN row[3] = "Aye" THEN "FOR" 
          WHEN row[3] = "No" THEN "AGAINST" 
          ELSE "DID_NOT_VOTE" END AS vote
CALL apoc.merge.relationship(person, vote, {}, {}, motion)
YIELD rel
RETURN count(*);

match (c:Constituency)
WHERE c.name contains "Ynys M"
SET c.name = "Ynys Mon";

match (p:Person)
WHERE p.name contains "Begley"
set p.name = "Órfhlaith Begley";

match (p:Party)
WHERE p.name contains "Sinn F"
SET p.name = "Sinn Féin";

load csv with headers from "https://github.com/mneedham/graphing-brexit/raw/master/data/pageviews.csv" AS row
MATCH (p:Person {name: row.person})
SET p.pageviews = toInteger(row.pageviews);

call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mps_formatted.json")
YIELD value
MATCH (p:Person)
WHERE p.name = value.name
SET p.id = value.person_id;

call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mps_20190301_formatted.json")
YIELD value
MATCH (p:Person)
WHERE p.name = value.name
SET p.id = value.person_id;
    
call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mp_events.json")
YIELD value
MATCH (person:Person {id: value.personId})
UNWIND value.parties AS party
MERGE (pa:Party {name: party.party})
MERGE (person)-[memberOf:MEMBER_OF {start: date(party.start)}]->(pa)
SET memberOf.end = date(party.end);

call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mp_events.json")
YIELD value
OPTIONAL MATCH (person:Person {id: value.personId})
WITH value, person WHERE person is null
match (other:Person) WHERE other.name contains split(value.name, " ")[-1]
WITH value, person, other, 
     apoc.text.sorensenDiceSimilarity(other.name, value.name) AS sorensen,
     apoc.text.jaroWinklerDistance(other.name, value.name) AS leven
ORDER BY value, apoc.coll.avg([leven, sorensen]) DESC
WITH value, person, collect({other: other, sorensen:sorensen, leven: leven})[0] AS closest
SET closest.other.id = value.personId;

call apoc.load.json("https://github.com/mneedham/graphing-brexit/raw/master/data/mp_events.json")
YIELD value
OPTIONAL MATCH (person:Person {id: value.personId})
WITH value, person WHERE person is null
match (other:Person) where not(exists(other.id))
WITH value, person, other, 
     apoc.text.sorensenDiceSimilarity(other.name, value.name) AS sorensen,
     apoc.text.jaroWinklerDistance(other.name, value.name) AS leven
ORDER BY value, apoc.coll.avg([leven, sorensen]) DESC
WITH value, person, collect({other: other, sorensen:sorensen, leven: leven})[0] AS closest
SET closest.other.id = value.personId;

MATCH (m:Motion)<-[vote]-(person:Person)
WHERE m.date = date({year: 2019, month: 3, day:27})
MATCH (person)-[memberOf:MEMBER_OF]->(party) 
WHERE memberOf.start <= m.date AND (not(exists(memberOf.end)) OR m.date <= memberOf.end)
WITH m, party, CASE WHEN type(vote) = "FOR" THEN 1 WHEN type(vote) = "DID_NOT_VOTE" THEN 0.5 ELSE 0 END AS score
WITH m, party, avg(score) AS score, count(*) AS count
MERGE (party)-[averageVote:AVERAGE_VOTE]->(m)
SET averageVote.score = score;

// match (p:Person)-[:MEMBER_OF]->(pa:Party)
// call apoc.create.addLabels(p, [apoc.text.replace(pa.name, " ", "")]) yield node
// RETURN count(*);