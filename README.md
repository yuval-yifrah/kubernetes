# run wordpress app on kubernetes:
please do the following steps:  

## download minikube:  
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64  
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64  
## download kubectl:  
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"  
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check  
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl  
## start minikube
minikube start  

## create a new namespace  
kubectl create namespace wordpress  

## create new secret  
PASSWORD=$(aws ecr get-login-password --region us-east-1)
kubectl create secret docker-registry ecr-secret \
  --docker-server=992382545251.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$PASSWORD \
  -n wordpress  
  
## download helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh 
./get_helm.sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

## run the app
enter the mini_kube_deployment directory  
bash run_all.sh  


