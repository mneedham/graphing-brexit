import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

from neo4j import GraphDatabase
import numpy as np

driver = GraphDatabase.driver("bolt://localhost")
with driver.session() as session:
    result = session.run("""
    MATCH (party:Party)-[vote:AVERAGE_VOTE]->(motion:Motion)
    RETURN party.name AS party, collect(vote.score) AS scores
    """)
    result = [{"party": row["party"], "scores": row["scores"]} for row in result]
    votes = np.array([row["scores"] for row in result]) 
    parties = np.array([row["party"] for row in result])
    votes = StandardScaler().fit_transform(votes)
    pca = PCA(n_components=2)
    principal_components = pca.fit_transform(votes)
    principal_df = pd.DataFrame(data = principal_components, columns = ['principal component 1', 'principal component 2'])
    print(principal_df)
    final_df = pd.concat([principal_df, pd.DataFrame({"target":parties})], axis = 1)
    fig = plt.figure(figsize = (8,8))
    ax = fig.add_subplot(1,1,1) 
    ax.set_xlabel('Principal Component 1', fontsize = 15)
    ax.set_ylabel('Principal Component 2', fontsize = 15)
    ax.set_title('2 component PCA', fontsize = 20)
    targets = parties
    colors = ['r', 'g', 'b', 'm', 'k', 'c', 'y', 'aqua', 'royalblue', 'slategrey', 'silver']
    for target, color in zip(targets,colors):
        indicesToKeep = final_df['target'] == target
        ax.scatter(final_df.loc[indicesToKeep, 'principal component 1']
                , final_df.loc[indicesToKeep, 'principal component 2']
                , c = color
                , s = 50)
    ax.legend(targets)
    ax.grid()
    plt.show()


url = "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data"
# load dataset into Pandas DataFrame
df = pd.read_csv(url, names=['sepal length','sepal width','petal length','petal width','target'])

features = ['sepal length', 'sepal width', 'petal length', 'petal width']
# Separating out the features
x = df.loc[:, features].values
# Separating out the target
y = df.loc[:,['target']].values
# Standardizing the features
x = StandardScaler().fit_transform(x)

pca = PCA(n_components=2)
principalComponents = pca.fit_transform(x)
principalDf = pd.DataFrame(data = principalComponents
             , columns = ['principal component 1', 'principal component 2'])


finalDf = pd.concat([principalDf, df[['target']]], axis = 1)

fig = plt.figure(figsize = (8,8))
ax = fig.add_subplot(1,1,1) 
ax.set_xlabel('Principal Component 1', fontsize = 15)
ax.set_ylabel('Principal Component 2', fontsize = 15)
ax.set_title('2 component PCA', fontsize = 20)
targets = ['Iris-setosa', 'Iris-versicolor', 'Iris-virginica']
colors = ['r', 'g', 'b']
for target, color in zip(targets,colors):
    indicesToKeep = finalDf['target'] == target
    ax.scatter(finalDf.loc[indicesToKeep, 'principal component 1']
               , finalDf.loc[indicesToKeep, 'principal component 2']
               , c = color
               , s = 50)
ax.legend(targets)
ax.grid()

plt.show()