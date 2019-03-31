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
SET p.pageviews = toInteger(row.pageviews)Sinn Féin;;