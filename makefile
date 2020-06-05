build:
	docker build -t bahorn/nginx-rtmp . 

run:
	docker run -it -p 1935:1935 -p 8080:80 --rm bahorn/nginx-rtmp
