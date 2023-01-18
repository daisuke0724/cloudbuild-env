apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudbuild
  labels:
    app: cloudbuild
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudbuild
  template:
    metadata:
      labels:
        app: cloudbuild
    spec:
      serviceAccountName: ksa
      containers:
        - name: nginx
          image: gcr.io/PROJECT_ID/nginx:SHORT_SHA
          ports:
            - containerPort: 80
        - name: php-fpm
          image: gcr.io/PROJECT_ID/php:SHORT_SHA
          ports:
            - containerPort: 9000
          env:
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: username
            - name: DB_PASS
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: password
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: database
        - name: cloud-sql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.17
          command:
            - "/cloud_sql_proxy"
            - "-instances=PROJECT_ID:asia-northeast1:network=tcp:3306"
          securityContext:
            runAsNonRoot: true
      volumes:
        - name: volume
          persistentVolumeClaim:
            claimName: volume-pvc
        - name: shared-files
          emptyDir: { }
---
apiVersion: v1
kind: Service
metadata:
  name: cloudbuild
spec:
  selector:
    app: cloudbuild
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: volume-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10k
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ksa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: "gsa@PROJECT_ID.iam.gserviceaccount.com"
