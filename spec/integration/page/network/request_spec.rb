require 'spec_helper'

RSpec.describe 'Request' do
  it 'should return navigation bit when navigating to image', sinatra: true do
    with_page do |page|
      requests = []
      page.on('request', ->(req) { requests << req })
      page.goto("#{server_prefix}/pprt.png")

      expect(requests.first.navigation_request?).to eq(true)
    end
  end

  it 'should set bodySize and headersSize', sinatra: true do
    with_page do |page|
      page.goto(server_empty_page)
      request = page.expect_event('request') do
        page.evaluate("() => fetch('./get', { method: 'POST', body: '12345'}).then(r => r.text())")
      end
      request.response.finished
      expect(request.sizes[:requestBodySize]).to eq(5)
      expect(request.sizes[:requestHeadersSize]).to be >= 300
    end
  end

  it 'should should set bodySize to 0 if there was no body', sinatra: true do
    with_page do |page|
      page.goto(server_empty_page)
      request = page.expect_event('request') do
        page.evaluate("() => fetch('./get').then(r => r.text())")
      end
      request.response.finished
      expect(request.sizes[:requestBodySize]).to eq(0)
      expect(request.sizes[:requestHeadersSize]).to be >= 300
    end
  end

  it 'should should set bodySize, headersSize, and transferSize', sinatra: true do
    sinatra.get('/__get') { 'abc134' }

    with_page do |page|
      page.goto(server_empty_page)
      response = page.expect_event('response') do
        page.evaluate("() => fetch('/__get').then(r => r.text())")
      end
      response.finished
      sizes = response.request.sizes
      expect(sizes[:responseBodySize]).to eq(6)
      expect(sizes[:responseHeadersSize]).to be >= 70
      expect(sizes[:responseTransferSize]).to be >= 80
    end
  end

  it 'should should set bodySize to 0 when there was no response body', sinatra: true do
    sinatra.get('/__get') { '' }

    with_page do |page|
      page.goto(server_empty_page)
      response = page.expect_event('response') do
        page.evaluate("() => fetch('/__get').then(r => r.text())")
      end
      response.finished
      sizes = response.request.sizes
      expect(sizes[:responseBodySize]).to eq(0)
      expect(sizes[:responseHeadersSize]).to be >= 70
      expect(sizes[:responseTransferSize]).to be >= 70
    end
  end
end
