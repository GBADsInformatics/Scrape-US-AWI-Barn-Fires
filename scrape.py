import requests
from bs4 import BeautifulSoup
import pandas as pd
import sys
from datetime import datetime

# Python3 program Split camel case
# string to individual strings

def camel_case_split(str):
	words = [[str[0]]]

	for c in str[1:]:
		if words[-1][-1].islower() and c.isupper():
			words.append(list(c))
		else:
			words[-1].append(c)

	return [''.join(word) for word in words]


outpath = sys.argv[1]

for year in ['2021', '2022', '2023']:

    url = 'https://awionline.org/content/%s-barn-fire-statistics-state' % year

    data = requests.get(url).text

    # Creating BeautifulSoup object
    soup = BeautifulSoup(data, 'html.parser')

    # Find all tables
    # tables = soup.find_all('table')
    # print(tables)

    # find table of class table-barn-fires
    table = soup.find('table', class_='table-barn-fires')

    # create df with columns related to data that will be scraped
    df = pd.DataFrame(columns=['state-name', 'date', 'deaths', 'species'])

    # get and organize output
    for row in table.tbody.find_all('tr'):
        columns = row.find_all('td')
        if(columns != []):
            try: 
                state_name = columns[0].text.strip()
                date = columns[1].span.contents[0].strip()
                deaths = columns[2].span.contents[0].strip()
                species = columns[3].span.contents[0].strip()
                df = df.append({'state-name':state_name, 
                    'date':date, 
                    'deaths':deaths, 
                    'species':species}, ignore_index=True)
            except AttributeError:
                print('Error')

    # deal with state-name column 
    names = df.loc[:,'state-name']

    state = []
    city = []

    for i in names: 

        names_split = camel_case_split(i)
        state.append(names_split[0])
        city.append(names_split[1])
    
    df['state'] = state
    df['city'] = city
    df = df.drop(columns = ['state-name']) 

    # convert dates to iso standard
    dates = df.loc[:,'date']

    date_list = []

    for i in dates: 
        month, day, year = i.split(" ")

        if month == 'June':
             month = 'Jun'

        day = day[:-1]

        if int(day) < 10: 
            day = '0%s' % day

        date_str = '%s %s %s' % (day, month, year)
        
        d = datetime.strptime(date_str, "%d %b %Y")
        d = d.strftime('%Y-%m-%d')

        date_list.append(d)

    df['date'] = date_list

    # Save to outfile
    outfile = '%s/AWI_barnfires_%s.csv' % (outpath, year)
    df.to_csv(outfile, index=False)


