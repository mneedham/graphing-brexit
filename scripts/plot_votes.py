import matplotlib.pyplot as plt
import numpy as np
from neo4j import GraphDatabase

driver = GraphDatabase.driver("bolt://localhost")

with driver.session() as session:
    for division in ["386", "387", "388", "389", "390", "391", "392", "392"]:
        rows = session.run("""
        MATCH (m:Motion {division: $division})
        RETURN m.name AS motion
        """, {"division": division})
        motion = rows.peek()["motion"]
        
        rows = session.run("""
        MATCH (p:Party)-[vote:AVERAGE_VOTE]->(m:Motion {division: $division})
        RETURN p.name AS party, vote.score AS score, m.name AS motion
        ORDER BY party
        """, {"division": division})

        result = [{"party": row["party"], "score": row["score"]} for row in rows ]

        plt.rcdefaults()
        fig, ax = plt.subplots()

        parties = [item["party"] for item in result]
        y_pos = np.arange(len(parties))
        scores = [item["score"] for item in result]

        ax.barh(y_pos, scores, align='center')
        ax.set_yticks(y_pos)
        ax.set_yticklabels(parties)
        ax.invert_yaxis()  

        ax.set_title(motion)

        ax.set_xlim([0,1])
        plt.xticks([0, 0.5, 1], ["Against", "Did Not Vote", "For"])
        fig.set_size_inches(16.5, 10.5)
        fig.savefig(f"images/{division}.png", bbox_inches='tight')