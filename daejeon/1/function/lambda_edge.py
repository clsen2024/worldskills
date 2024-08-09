import urllib3

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    print(event)
    stype = request['uri'].split('/')[-1]
    
    http = urllib3.PoolManager()
    res = http.request('GET', f'http://hrdkorea-app-alb-823958990.ap-northeast-2.elb.amazonaws.com/healthcheck?path={stype}')
    status = res.status

    if not (status >= 500 and status < 600):
        print("AP is Healthy.")
        return request

    print("AP is Unhealthy. Request to US.")
    
    us_domain = "hrdkorea-app-alb-1113371801.us-east-1.elb.amazonaws.com"
    request['origin'] = {
        'custom': {
            'domainName': us_domain,
            'keepaliveTimeout': 5,
            'path': '',
            'port': 80,
            'protocol': 'http',
            'readTimeout': 5,
            'sslProtocols': ['TLSv1', 'TLSv1.1'],
            'timeout': 5
        }
    }
    request['headers']['host'] = [{'key': 'host', 'value': us_domain}]
    
    return request
