using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explotion : MonoBehaviour {

    public float detonationTimer = -10f;
    public float fullSize = 15f;

    private float expSpeed = .2f;
    private float windupSize = -3.2f;

    private float currentSize = 0f;

    // Start is called before the first frame update
    void Start() {

        detonationTimer -= Random.Range(2f, 5f);

        gameObject.transform.localScale = new Vector3(0, 0, 0);

        float rotationX = Random.Range(0f, 360f);
        float rotationY = Random.Range(-80f, 80f);
        float rotationZ = Random.Range(-80f, 80f);
        transform.localRotation = Quaternion.Euler(rotationX, rotationY, rotationZ);
    }

    // Update is called once per frame
    void FixedUpdate() {

        detonationTimer += Time.deltaTime;
        if (detonationTimer >= 0) {


            float x = detonationTimer;
            currentSize = expSpeed * Mathf.Pow(x, 2) + Mathf.Sqrt(expSpeed) * x * windupSize;
            gameObject.transform.localScale = new Vector3(1, 1, 1) * currentSize;
        }

        if (currentSize >= fullSize) {
            Destroy(gameObject);
        }
        
        Debug.Log(currentSize);
    }
}
