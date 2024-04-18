#!/bin/bash
tag_base="latest"

# Сборка
docker buildx build -f Dockerfile -t coralhl/dagu:$tag_base .
# Заливка в регистр
docker push coralhl/dagu:$tag_base
