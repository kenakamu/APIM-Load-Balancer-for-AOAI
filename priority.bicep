param apimName string = '<your APIM resource name>'
param aoaiOneUrl string = 'https://<AOAI account>.openai.azure.com/openai'
param aoaiTwoUrl string = 'https://<AOAI account>.openai.azure.com/openai'
param backendOne string = 'backendone'
param backendTwo string = 'backendtwo'
param loadBalancerId string = 'loadbalancer'

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

resource openaibackendone 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  name: backendOne
  parent: apim
  properties:{
    url:aoaiOneUrl
    protocol: 'http'
    circuitBreaker:{
      rules:[
        {
          failureCondition:{
            count: 1 // How many times the failure condition must be met
            errorReasons:['Server error']
            interval:'PT1H' // The time interval in which the failure condition must be met
            statusCodeRanges:[ // Speicify the status code ranges that will trigger the circuit breaker
              {
                min: 400
                max: 499 // 400-499 includes 429: Too many requests
              }
            ]
          }
          name:'CircuitBreakerRule'
          tripDuration:'PT15S' // The time interval to restart using the backend again
          acceptRetryAfter: true // Use RetryAfter in Policy level
        }
      ]}
  }
}

resource openaibackendtwo 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  name: backendTwo
  parent: apim
  properties:{
    url: aoaiTwoUrl
    protocol: 'http'
    circuitBreaker:{
      rules:[
        {
          failureCondition:{
            count: 1 // How many times the failure condition must be met
            errorReasons:['Server error']
            interval:'PT1H'
            statusCodeRanges:[
              {
                min: 400
                max: 499 // 400-499 includes 429: Too many requests
              }
            ]
          }
          name:'CircuitBreakerRule'
          tripDuration:'PT15S' // The time interval to restart using the backend again
          acceptRetryAfter: true // Use RetryAfter in Policy level
        }
      ]}
  }
}

resource loadbalance 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: loadBalancerId
  parent: apim
  properties: {
    description: 'Load balancer for multiple backends'
    type: 'Pool'
    pool: {
      services: [
        {
          id: '/backends/${backendOne}'
          priority: 1 // The lower priority will be used only when higher priority is not available
          weight: 50 // Loadbalance weight. As its racio, doesn't have to be 100 in total

        }
        {
          id: '/backends/${backendTwo}'
          priority: 2 // The lower priority will be used only when higher priority is not available
          weight: 50 // Loadbalance weight. As its racio, doesn't have to be 100 in total
        }
      ]
    }
  }
}
