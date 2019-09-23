import unittest
from read_mp import aggregate_events

class AggregateEvents(unittest.TestCase):
    def test_one_party(self):
        events = [
            {
                "constituency": "Walsall North",
                "party": "Conservative",
                "entered_house": "2017-06-09",
                "left_house": "9999-12-31",
                "entered_reason": "general_election",
                "left_reason": "still_in_office",
                "person_id": "25699",
                "full_name": "Eddie Hughes",
            }
        ]

        parties = aggregate_events(events)    
        self.assertEqual(parties, {
            "personId": "25699", 
            "name": "Eddie Hughes",
            "parties": [{"party": "Conservative", "start": "2017-06-09"}]
        })   

    def test_one_party_two_elections(self):
        events = [
            {
                "member_id": "40779",
                "house": "1",
                "constituency": "Merthyr Tydfil and Rhymney",
                "party": "Labour",
                "entered_house": "2015-05-08",
                "left_house": "2017-05-03",
                "entered_reason": "general_election",
                "left_reason": "dissolution",
                "person_id": "25289",
                "full_name": "Gerald Jones",
            },
            {
                "member_id": "41684",
                "house": "1",
                "constituency": "Merthyr Tydfil and Rhymney",
                "party": "Labour",
                "entered_house": "2017-06-09",
                "left_house": "9999-12-31",
                "entered_reason": "general_election",
                "left_reason": "still_in_office",
                "person_id": "25289",
                "full_name": "Gerald Jones",
            },

        ]

        parties = aggregate_events(events)    
        self.assertEqual(parties, {
            "personId": "25289", 
            "name": "Gerald Jones",
            "parties": [{"party": "Labour", "start": "2015-05-08"}]
        })  

    def test_empty_party(self):
        events = [
            {
                "member_id": "2069",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "",
                "entered_house": "1987-06-11",
                "left_house": "1992-03-16",
                "entered_reason": "general_election",
                "left_reason": "general_election",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },
            {
                "member_id": "2070",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "",
                "entered_house": "1992-04-09",
                "left_house": "1997-04-08",
                "entered_reason": "general_election",
                "left_reason": "general_election",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },
            {
                "member_id": "1",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "1997-05-01",
                "left_house": "2001-05-14",
                "entered_reason": "general_election",
                "left_reason": "general_election",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },   
            {
                "member_id": "687",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "2001-06-07",
                "left_house": "2005-04-11",
                "entered_reason": "general_election",
                "left_reason": "general_election_standing",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },
            {
                "member_id": "1604",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "2005-05-05",
                "left_house": "2010-04-12",
                "entered_reason": "general_election",
                "left_reason": "general_election_standing",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },     
            {
                "member_id": "40289",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "2010-05-06",
                "left_house": "2015-03-30",
                "entered_reason": "general_election",
                "left_reason": "general_election",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },                   
            {
                "member_id": "40928",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "2015-05-08",
                "left_house": "2017-05-03",
                "entered_reason": "general_election",
                "left_reason": "dissolution",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
            },
            {
                "member_id": "41707",
                "house": "1",
                "constituency": "Hackney North and Stoke Newington",
                "party": "Labour",
                "entered_house": "2017-06-09",
                "left_house": "9999-12-31",
                "entered_reason": "general_election",
                "left_reason": "still_in_office",
                "person_id": "10001",
                "title": "",
                "given_name": "Diane",
                "family_name": "Abbott",
                "full_name": "Diane Abbott",
                
            },

        ]

        parties = aggregate_events(events)    
        print(parties)
        self.assertEqual(parties, {
            "personId": "10001", 
            "name": "Diane Abbott",
            "parties": [{"party": "Labour", "start": "1987-06-11"}]
        })  



if __name__ == '__main__':
    unittest.main()