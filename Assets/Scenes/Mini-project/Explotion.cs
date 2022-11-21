using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explotion : MonoBehaviour {

    [Range(-10, 0)] public float detonationTimer = -10f;
    [Range(0, 5)] public float explotionSpeed = 2f;
    public int explotionSize = 15;
    [Range(0, 5)] public float windupSpeed = 2f;
    public int windupSize = 3;

    private float currentSize = 0f;

    // Start is called before the first frame update
    void Start() {

        detonationTimer -= Random.Range(1f, 3f);
        gameObject.transform.localScale = new Vector3(0, 0, 0);

        float rotationX = Random.Range(0f, 360f);
        float rotationY = Random.Range(-80f, 80f);
        float rotationZ = 0; // Random.Range(-80f, 80f);
        transform.localRotation = Quaternion.Euler(rotationX, rotationY, rotationZ);
    }

    // Update is called once per frame
    void FixedUpdate() {

        detonationTimer += Time.deltaTime;
        if (detonationTimer >= 0) {
            if (currentSize <= 0) {
                currentSize = Mathf.Pow(Mathf.Sqrt(windupSize) - windupSpeed * detonationTimer, 2) - windupSize;
            } else {
                currentSize += explotionSpeed * Time.deltaTime;
            }
            gameObject.transform.localScale = new Vector3(1, 1, 1) * currentSize;
        }

        if (currentSize >= explotionSize) {
            Destroy(gameObject);
        }
        
        Debug.Log(currentSize);
    }
}
