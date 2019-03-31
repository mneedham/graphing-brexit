from mwviews.api import PageviewsClient
from neo4j import GraphDatabase
import csv

p = PageviewsClient("mark-needham")
driver = GraphDatabase.driver("bolt://localhost", auth=("neo4j", "neo"))

# people = [
#     "Boris Johnson", "Theresa May", "Jacob Rees-Mogg"
# ]

with driver.session() as session:
  result = session.run("""
  MATCH (p:Person)
  RETURN p.name AS person
  """)
  people = [row["person"] for row in result]


# p.article_views("en.wikipedia", people,  start="20190325", end="20190330")
views = p.article_views("en.wikipedia", people,  start="20160624", end="20190330")
votes = {person: 0 for person in people }

for key in views.keys():
  for person_key in views[key].keys():
    person = person_key.replace("_", " ")
    if views[key][person_key]:
        votes[person] += views[key][person_key]


with open("data/pageviews.csv", "w") as pageviews_file:
  writer = csv.writer(pageviews_file, delimiter=",")
  writer.writerow(["person", "pageviews"])

  for vote in votes:
    writer.writerow([vote, votes[vote]])