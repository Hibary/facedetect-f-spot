#include "f-image-view.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <time.h>
#include <ctype.h>

#include "cls.h"


#define MAX_CLS_IN_STAGE 30

int *labels;
int *used;
int **images;
int **features;
int *w;

int pos_count;
int neg_count;
int img_count;
int feat_count;
int t;
int T;
int i;


int sum (int *tbl, int len) {
	
	int i;
	int sum=0;
	for(i=0; i<len; i++)
		sum+=tbl[i];
	return sum;
}
/// MakeVector img is a matrix of w * h
void MakeVector(int **img, int *vec, int w, int h)
{
	int i,j;
	
//	vec = malloc(w*h*sizeof(int));
	for (j=0; j<w; j++)
		for(i=0; i<h; i++)
			vec[i*w + j] = img[i][j];
	
	
}

// MakeArray: img is a vector with cols placed one after another
// (like matlab reshape )

int **MakeArray(int *img, int w, int h)
{
	int i,j;
	int **arr;
	arr = malloc(h*sizeof(int));
	for(i=0; i<h; i++)
		arr[i] = malloc(w*sizeof(int));
	for (j=0; j<w; j++)
		for(i=0; i<h; i++)
			arr[i][j] = img[j*h + i];
	return arr;
}
/// this in turn requires the image to be in a [x y] matrix !

void IntegralImage (int **img, int **dst, int w, int h) {
	int x,y;
	
	
	// fill in the first line
	dst[0][0]=img[0][0];
	for(x=1; x<w; x++)
		dst[x][0] = dst[x-1][0] + img[x][0];
	
	for(y=1; y<h; y++)
	{
		double line = img[0][y];
		dst[0][y] = dst[0][y-1] + line;
		for(x=0; x<w; x++)
		{
			line += img[x][y];
			dst[x][y] = dst[x][y-1] + line;
		}
	}
	
}

double ApplyFeature(int *f, int *img)
{
	/// f & img have to be vectors, really.
	/// of size 25*25
	int i;
	double wynik = 0.0f;
	for( i=0; i<625; i++)
	{
				wynik+=	f[i]*img[i];
	}
	return wynik;
}


WeakClassifier findWeakClassifier(int *f, int *fxIdx) {
	
	double e1 = 0.0;
	double e2 = 0.0;
	double min1;
	double min2;
	int min1Idx;
	int min2Idx;
	int i,j;
	WeakClassifier cls;
	double Tp,Tn,Sp,Sn;
	
	for(i=0; i<pos_count; i++)
		Tp += w[i];
	for(i=pos_count; i<img_count; i++)
		Tn += w[i];
	e2 = 1-e1;
	min1 = e1;
	min2 = e2;
	for(i=0; i<img_count; i++)
	{
		if(labels[i]==1)
			Sp += w[fxIdx[i]];
		else
			Sn += w[fxIdx[i]];
		
		e1 = ( Sp + (Tn - Sn));
		e2 = ( Sn + (Tp - Sp));
			
		if(e1<min1)
		{
			min1 = e1;
			min1Idx = i;
		}
		if(e2<min2)
		{
			min2 = e2;
			min2Idx = i;
		}
	}
	
	if(min1<min2)
	{
		cls.parity = 1;
		cls.theta = ApplyFeature(f, images[fxIdx[min1Idx]]);
		cls.error = min1;
	}
	else
	{
		cls.parity = -1;
		cls.theta = ApplyFeature(f, images[fxIdx[min2Idx]]);
		cls.error = min2;
	}
	
}		
int AddClassifier (StrongClassifier sc, WeakClassifier cls) {
	
	if(sc.count >= MAX_CLS_IN_STAGE)
		return -1;
	
	sc.sc[sc.count] = cls;
	sc.count++;
	return 0;
	
}


int AdaBoost (StrongClassifier sc) {
	int i,j,T;
	double beta;
	double *alfa;
	int *fxIdx;	
	T = 20; // maximum number of weak classifiers in a strong one
	if(T > MAX_CLS_IN_STAGE) 
		return -1;
	
	img_count = pos_count + neg_count;
	
	for(i=0; i<pos_count; i++)
		labels[i] = 1;
	
	for(i=pos_count; i<img_count; i++)
		labels[i] = -1;
	
	for(i=0; i<img_count; i++)
		if(labels[i])
			w[i] = 0.5*1/pos_count;
		else
			w[i] = 0.5*1/neg_count;
		
	
		/// proceed to boosting round t of T
	for (t=0; t<T; t++)	{
			
		int min_error = 0;
		int min_idx = 0;
	
			/// 1. normalize the weights
		int w_sum = sum(w,img_count);
	
		for(i=0; i<img_count; i++)
			w[i] /= w_sum;
			// end normalize
	 	WeakClassifier cls[feat_count];
			/// 2. For each feature train a classifier h_j which is restricted to using a single feature
			/// The error is evaluated with respect to wt, ej = S_i w_i |h_j(x_i) - y_i|.
			
			 /// Calculate the features and sort by values
		int **x; // the images
		for(j=0; j<feat_count; j++)	{
			
			if(used[j]) 
				continue;
			
			double values[img_count];
			
			for(i=0; i<img_count; i++)
				values[i] = ApplyFeature(features[j],x[i]);
			//sort(values,fxIdx);
			
			cls[j] = findWeakClassifier(features[j],fxIdx);
			
			if(cls[j].error < min_error) {
				min_error = cls[j].error;
				min_idx = j;
			}
		}
			
			/// 3. Choose the classifier, h_t, with the lowest eror e_t.
			AddClassifier(sc, cls[min_idx]);
			used[min_idx] = 1;
			/// 4. Update the weights
			
			
			beta = min_error / (1 - min_error);
//			alfa[t] = log(1/beta);
			for(i=0; i<img_count; i++)
			{
				
//				w[i] = w[i]*pow(beta, 1-abs( labels[i]- ApplyClassifier(cls[min_idx],images[i]) ) );
			}
			sc.theta += 0.5 * alfa[t];
			/// proceed to the next round
			
		}
}
 int ApplyClassifier(WeakClassifier cls, int *img)
 {
 	double wynik = ApplyFeature(cls.f,img);
 	
 	if (cls.parity == 1)
 	{
 		if(wynik < cls.theta)
 		{
 		//	printf("accepted!\n");
 			return 1;
 		} else 
 		{
 	//		printf("dropped!\n");
 			return 0;
 		}
 	}
 		else
 		{
 			if(-1*wynik > -1*cls.theta)
 			{
 //				printf("accepted!\n");
 				return 1;
 			} else {
// 				printf("dropped!\n");
 				return 0;
 			}
 		}	
 } 
 /// The detector, input: img as a 25*25 vector
 int ApplyStrongClassifier ( StrongClassifier strong, int *img ) {
	int i,j,clsf;
	double sum=0.0;
 	double th=0;
 	
 	
 	for (i=0; i<strong.count; i++)
	 		th+=strong.sc[i].alpha * ApplyClassifier(strong.sc[i], img);
	 //printf("klas o feat = %d theta = %f mowi, ze f=%f i H=%d\n",strong.count, strong.theta,th,(th>strong.theta)?1:-1);
 	if(th < strong.theta) return -1;
 	return 1;
 	//return (th<sc.theta)?0:1;
 }
 
int Detect (int *img) {

//	int th;
	
	int notFace = 0;
	int T=1;
	int t=0;
	
 	for (t=0; t<T && notFace==0; t++)
 	{
 	//	printf("round %d, strong classifier has %d features!\n",t,sc.cls_count);
 		//if(!ApplyStrongClassifier(sc,img))
			notFace = 1;
 	}
 		
 	//draw the box
 	if(!notFace)
 	{
 	//	printf("window accepted!"); 
 		return 1;
 	}
 		else return 0;	 
}

int RunCascade (int *img) {
	int i=0;
	int T=0;
	int clsf = 0;
	
	for(i=0; i<num_stages; i++) {
		
		//T = stages[i];
		if ( ApplyStrongClassifier(st[i],img) == -1)
		{
//			printf("rej by stage %d\n",i);
			return 0;
		}
	}
	return 1;
}
 int detect_ada( unsigned char *pixbuf,int width, int height,
 				int rowstride, int n_channels) {
	
	int **iimage;
	int **img;
	int **arr;
	int *vec;
	int i,j;
	int res;
	vec = malloc(625*sizeof(int));
	iimage = malloc(25*sizeof(int));
	for(i=0; i<25; i++)
		iimage[i] = malloc(25*sizeof(int));

	img = malloc(25*sizeof(int));
	for(i=0; i<25; i++)
		img[i] = malloc(25*sizeof(int));

	//arr = MakeArray(image,25,25);
	
	  //p = pixels + y * rowstride + x * n_channels;
	  //return;	
	  unsigned char p;
	  //printf("it is a %d by %d, %d channel image with a %d stride\n",width,height,n_channels,rowstride);
	for (i = 0; i < 25; i++) {
		for (j = 0; j < 25; j++) {
	
			img[i][j] = (int)*(pixbuf + i*rowstride + j*n_channels); // really pick only the R channel
		}
		
	}
	

		
	IntegralImage(img,iimage,25,25);
	
	setSc();
	
	//printf("starting detection!\n");
	MakeVector(iimage,vec,25,25);
	
	res = RunCascade(vec);
	
	for(i=0; i<25; i++)
		free(iimage[i]);
	for(i=0; i<25; i++)
		free(img[i]);
	free(iimage);
	free(img);
	free(vec);
	return res;
}
